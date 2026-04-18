import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'rosbridge_protocol.dart';

/// Trạng thái kết nối tới rosbridge.
enum RosConnectionStatus { disconnected, connecting, connected, error }

/// Tuỳ chọn khi [RosbridgeClient] khởi tạo.
class RosbridgeClientOptions {
  final bool autoReconnect;
  final Duration minBackoff;
  final Duration maxBackoff;
  final Duration connectTimeout;
  final String? authToken;

  const RosbridgeClientOptions({
    this.autoReconnect = true,
    this.minBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
    this.connectTimeout = const Duration(seconds: 6),
    this.authToken,
  });
}

/// Handle đăng ký subscribe 1 topic — cancel để unsubscribe.
class RosSubscription {
  RosSubscription._(this._client, this._topic, this._id, this._controller);

  final RosbridgeClient _client;
  final String _topic;
  final String _id;
  final StreamController<Map<String, dynamic>> _controller;
  bool _closed = false;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  String get topic => _topic;

  Future<void> cancel() async {
    if (_closed) return;
    _closed = true;
    await _client._unsubscribe(_id, _topic);
    await _controller.close();
  }
}

/// Handle cho 1 action goal — cancel, lắng nghe feedback/result.
class ActionGoalHandle {
  ActionGoalHandle._(
    this._client,
    this.actionName,
    this.actionType,
    this.goalId,
    this._feedbackCtrl,
    this._resultCompleter,
  );

  final RosbridgeClient _client;
  final String actionName;
  final String actionType;
  final String goalId;
  final StreamController<Map<String, dynamic>> _feedbackCtrl;
  final Completer<ActionResult> _resultCompleter;
  ActionGoalStatus _status = ActionGoalStatus.accepted;

  Stream<Map<String, dynamic>> get feedback => _feedbackCtrl.stream;
  Future<ActionResult> get result => _resultCompleter.future;
  ActionGoalStatus get status => _status;

  Future<void> cancel() async {
    await _client._cancelActionGoal(actionName, goalId);
  }
}

/// Kết quả cuối cùng của 1 action goal.
class ActionResult {
  final ActionGoalStatus status;
  final Map<String, dynamic> values;
  const ActionResult({required this.status, required this.values});

  bool get succeeded => status == ActionGoalStatus.succeeded;
}

/// Raw rosbridge v2 WebSocket client — độc lập, không phụ thuộc roslibdart.
///
/// Hỗ trợ publish/subscribe/call_service/send_action_goal + auto-reconnect.
class RosbridgeClient {
  RosbridgeClient(this.url, {this.options = const RosbridgeClientOptions()})
      : _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  final String url;
  final RosbridgeClientOptions options;
  final Logger _logger;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSub;

  final _statusCtrl = StreamController<RosConnectionStatus>.broadcast();
  RosConnectionStatus _status = RosConnectionStatus.disconnected;

  final _subscriptions = <String, RosSubscription>{}; // key = subscribe id
  final _topicRefCount = <String, int>{};             // key = topic name
  final _pendingServices =
      <String, Completer<Map<String, dynamic>>>{};     // key = service id
  final _actionGoals = <String, ActionGoalHandle>{};   // key = goal id
  final _advertisedTopics = <String, String>{};        // topic -> type

  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  int _idCounter = 0;
  bool _userClosed = false;

  Stream<RosConnectionStatus> get statusStream => _statusCtrl.stream;
  RosConnectionStatus get status => _status;
  bool get isConnected => _status == RosConnectionStatus.connected;

  String _nextId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

  void _setStatus(RosConnectionStatus s) {
    if (_status == s) return;
    _status = s;
    _statusCtrl.add(s);
  }

  Future<void> connect() async {
    if (_status == RosConnectionStatus.connected ||
        _status == RosConnectionStatus.connecting) {
      return;
    }
    _userClosed = false;
    _setStatus(RosConnectionStatus.connecting);
    try {
      final ch = WebSocketChannel.connect(Uri.parse(url));
      await ch.ready.timeout(options.connectTimeout);
      _channel = ch;
      _socketSub = ch.stream.listen(
        _onMessage,
        onDone: _onSocketDone,
        onError: _onSocketError,
        cancelOnError: true,
      );
      _setStatus(RosConnectionStatus.connected);
      _reconnectAttempt = 0;
      _logger.i('rosbridge connected: $url');

      if (options.authToken != null && options.authToken!.isNotEmpty) {
        _send({
          'op': RosbridgeOp.authenticate,
          'token': options.authToken,
        });
      }

      // Tái lập các subscribe/advertise sau reconnect.
      _resubscribeAll();
      _readvertiseAll();
    } on TimeoutException catch (e) {
      _logger.w('connect timeout: $e');
      _setStatus(RosConnectionStatus.error);
      _scheduleReconnect();
    } catch (e, st) {
      _logger.e('connect failed: $e', error: e, stackTrace: st);
      _setStatus(RosConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  void _resubscribeAll() {
    for (final sub in _subscriptions.values) {
      _send({
        'op': RosbridgeOp.subscribe,
        'id': sub._id,
        'topic': sub._topic,
      });
    }
  }

  void _readvertiseAll() {
    _advertisedTopics.forEach((topic, type) {
      _send({'op': RosbridgeOp.advertise, 'topic': topic, 'type': type});
    });
  }

  void _onSocketDone() {
    _logger.w('rosbridge socket closed');
    _cleanupSocket();
    _setStatus(RosConnectionStatus.disconnected);
    if (!_userClosed) _scheduleReconnect();
  }

  void _onSocketError(Object error, StackTrace st) {
    _logger.e('rosbridge socket error: $error', error: error, stackTrace: st);
    _cleanupSocket();
    _setStatus(RosConnectionStatus.error);
    if (!_userClosed) _scheduleReconnect();
  }

  void _cleanupSocket() {
    _socketSub?.cancel();
    _socketSub = null;
    try {
      _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;
  }

  void _scheduleReconnect() {
    if (!options.autoReconnect || _userClosed) return;
    _reconnectTimer?.cancel();
    final base = options.minBackoff.inMilliseconds;
    final mx = options.maxBackoff.inMilliseconds;
    final ms = math.min(mx, base * math.pow(2, _reconnectAttempt).toInt());
    _reconnectAttempt++;
    _logger.i('reconnect in ${ms}ms (attempt $_reconnectAttempt)');
    _reconnectTimer = Timer(Duration(milliseconds: ms), () {
      if (!_userClosed) connect();
    });
  }

  Future<void> disconnect() async {
    _userClosed = true;
    _reconnectTimer?.cancel();
    _cleanupSocket();
    _setStatus(RosConnectionStatus.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    for (final s in _subscriptions.values) {
      await s._controller.close();
    }
    _subscriptions.clear();
    for (final g in _actionGoals.values) {
      if (!g._resultCompleter.isCompleted) {
        g._resultCompleter.complete(
          const ActionResult(status: ActionGoalStatus.aborted, values: {}),
        );
      }
      await g._feedbackCtrl.close();
    }
    _actionGoals.clear();
    await _statusCtrl.close();
  }

  void _send(Map<String, dynamic> frame) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(frame));
    } catch (e, st) {
      _logger.e('send failed: $e', error: e, stackTrace: st);
    }
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      _logger.w('malformed rosbridge frame: $e');
      return;
    }
    final op = frame['op'] as String? ?? '';
    switch (op) {
      case RosbridgeOp.publish:
        _handlePublish(frame);
      case RosbridgeOp.serviceResponse:
        _handleServiceResponse(frame);
      case RosbridgeOp.actionFeedback:
        _handleActionFeedback(frame);
      case RosbridgeOp.actionResult:
        _handleActionResult(frame);
      case RosbridgeOp.status:
        final level = frame['level'];
        final msg = frame['msg'];
        if (level == 'error') {
          _logger.w('rosbridge status: $msg');
        }
      default:
        break;
    }
  }

  void _handlePublish(Map<String, dynamic> frame) {
    final topic = frame['topic'] as String?;
    final msg = frame['msg'] as Map<String, dynamic>?;
    if (topic == null || msg == null) return;
    for (final sub in _subscriptions.values) {
      if (sub._topic == topic && !sub._closed) {
        sub._controller.add(msg);
      }
    }
  }

  void _handleServiceResponse(Map<String, dynamic> frame) {
    final id = frame['id'] as String?;
    if (id == null) return;
    final completer = _pendingServices.remove(id);
    if (completer == null) return;
    final ok = (frame['result'] ?? frame['values'] != null) == true ||
        frame['values'] != null;
    if (ok) {
      completer.complete(
          (frame['values'] as Map<String, dynamic>?) ?? <String, dynamic>{});
    } else {
      completer.completeError(StateError(
          'service failed: ${frame['values'] ?? frame['result']}'));
    }
  }

  void _handleActionFeedback(Map<String, dynamic> frame) {
    final id = frame['id'] as String?;
    final values = frame['values'] as Map<String, dynamic>?;
    if (id == null) return;
    final handle = _actionGoals[id];
    if (handle == null) return;
    if (values != null && !handle._feedbackCtrl.isClosed) {
      handle._feedbackCtrl.add(values);
    }
  }

  void _handleActionResult(Map<String, dynamic> frame) {
    final id = frame['id'] as String?;
    final values = (frame['values'] as Map<String, dynamic>?) ?? const {};
    final statusCode = (frame['status'] as num?)?.toInt() ??
        ((frame['result'] == true)
            ? ActionGoalStatus.succeeded.code
            : ActionGoalStatus.aborted.code);
    if (id == null) return;
    final handle = _actionGoals.remove(id);
    if (handle == null) return;
    final status = ActionGoalStatus.fromCode(statusCode);
    handle._status = status;
    if (!handle._resultCompleter.isCompleted) {
      handle._resultCompleter
          .complete(ActionResult(status: status, values: values));
    }
    handle._feedbackCtrl.close();
  }

  // ------- High-level API -------

  /// Advertise + publish 1 message tới topic.
  void publish(
      {required String topic,
      required String type,
      required Map<String, dynamic> msg}) {
    if (!_advertisedTopics.containsKey(topic)) {
      _advertisedTopics[topic] = type;
      _send({'op': RosbridgeOp.advertise, 'topic': topic, 'type': type});
    }
    _send({'op': RosbridgeOp.publish, 'topic': topic, 'msg': msg});
  }

  /// Ngừng advertise topic (ít khi cần).
  void unadvertise(String topic) {
    if (_advertisedTopics.remove(topic) != null) {
      _send({'op': RosbridgeOp.unadvertise, 'topic': topic});
    }
  }

  /// Subscribe topic, trả về [RosSubscription]. Cancel để unsubscribe.
  RosSubscription subscribe({
    required String topic,
    required String type,
    int throttleRateMs = 0,
    int queueLength = 1,
    String? compression,
  }) {
    final id = _nextId('sub');
    final ctrl = StreamController<Map<String, dynamic>>.broadcast();
    final sub = RosSubscription._(this, topic, id, ctrl);
    _subscriptions[id] = sub;
    _topicRefCount.update(topic, (v) => v + 1, ifAbsent: () => 1);
    _send({
      'op': RosbridgeOp.subscribe,
      'id': id,
      'topic': topic,
      'type': type,
      'throttle_rate': throttleRateMs,
      'queue_length': queueLength,
      if (compression != null) 'compression': compression,
    });
    return sub;
  }

  Future<void> _unsubscribe(String id, String topic) async {
    _subscriptions.remove(id);
    final n = (_topicRefCount[topic] ?? 1) - 1;
    if (n <= 0) {
      _topicRefCount.remove(topic);
      _send({'op': RosbridgeOp.unsubscribe, 'id': id, 'topic': topic});
    } else {
      _topicRefCount[topic] = n;
    }
  }

  /// Gọi service 1 lần, trả về `values` (null nếu không có).
  Future<Map<String, dynamic>?> callService({
    required String name,
    required String type,
    Map<String, dynamic> request = const {},
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final id = _nextId('svc');
    final completer = Completer<Map<String, dynamic>>();
    _pendingServices[id] = completer;
    _send({
      'op': RosbridgeOp.callService,
      'id': id,
      'service': name,
      'type': type,
      'args': request,
    });
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _pendingServices.remove(id);
      rethrow;
    }
  }

  /// Gửi 1 action goal — trả về handle để theo dõi feedback/result.
  ActionGoalHandle sendActionGoal({
    required String actionName,
    required String actionType,
    required Map<String, dynamic> goal,
    bool wantFeedback = true,
  }) {
    final id = _nextId('goal');
    final fb = StreamController<Map<String, dynamic>>.broadcast();
    final rc = Completer<ActionResult>();
    final handle = ActionGoalHandle._(
        this, actionName, actionType, id, fb, rc);
    _actionGoals[id] = handle;
    _send({
      'op': RosbridgeOp.sendActionGoal,
      'id': id,
      'action': actionName,
      'action_type': actionType,
      'args': goal,
      'feedback': wantFeedback,
    });
    return handle;
  }

  Future<void> _cancelActionGoal(String action, String goalId) async {
    _send({
      'op': RosbridgeOp.cancelActionGoal,
      'id': goalId,
      'action': action,
    });
  }
}
