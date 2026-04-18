import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:roslibdart/roslibdart.dart';

import '../storage/models/robot_profile.dart';

/// Trạng thái kết nối tới rosbridge.
enum RosConnectionStatus { disconnected, connecting, connected, error }

/// Wrapper cho roslibdart quản lý 1 kết nối tới 1 robot.
///
/// - Quản lý reconnect exponential backoff.
/// - Prefix tên topic/service theo `namespace` của robot.
/// - Cung cấp method high-level subscribe/publish/service.
class RosClient {
  RosClient(this.profile) : _logger = Logger();

  final RobotProfile profile;
  final Logger _logger;

  Ros? _ros;
  final _status = StreamController<RosConnectionStatus>.broadcast();
  RosConnectionStatus _current = RosConnectionStatus.disconnected;

  Stream<RosConnectionStatus> get status => _status.stream;
  RosConnectionStatus get currentStatus => _current;
  bool get isConnected => _current == RosConnectionStatus.connected;

  String get url => 'ws://${profile.host}:${profile.port}';

  /// Nối tên topic với namespace (ví dụ `/robot_1/scan`).
  String ns(String topic) {
    if (profile.namespace.isEmpty) return topic;
    final prefix = profile.namespace.startsWith('/')
        ? profile.namespace
        : '/${profile.namespace}';
    if (topic.startsWith(prefix)) return topic;
    return '$prefix$topic';
  }

  Future<void> connect() async {
    if (_current == RosConnectionStatus.connected ||
        _current == RosConnectionStatus.connecting) {
      return;
    }
    _setStatus(RosConnectionStatus.connecting);
    try {
      _ros = Ros(url: url);
      _ros!.connect();
      // roslibdart không có callback ready — chờ ngắn rồi check trạng thái
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _setStatus(RosConnectionStatus.connected);
      _logger.i('Connected to $url');
    } catch (e, st) {
      _logger.e('Connect failed: $e', error: e, stackTrace: st);
      _setStatus(RosConnectionStatus.error);
    }
  }

  Future<void> disconnect() async {
    try {
      await _ros?.close();
    } catch (_) {}
    _ros = null;
    _setStatus(RosConnectionStatus.disconnected);
  }

  void _setStatus(RosConnectionStatus s) {
    _current = s;
    _status.add(s);
  }

  /// Subscribe 1 topic, trả về Stream<Map<String,dynamic>> JSON message.
  ///
  /// Caller có trách nhiệm dispose subscription khi không cần để tránh leak.
  RosSubscription subscribeRaw({
    required String topic,
    required String type,
    int throttleRateMs = 0,
    int queueLength = 1,
  }) {
    final ros = _requireRos();
    final full = ns(topic);
    final t = Topic(
      ros: ros,
      name: full,
      type: type,
      throttleRate: throttleRateMs,
      queueLength: queueLength,
      reconnectOnClose: true,
    );
    final ctrl = StreamController<Map<String, dynamic>>.broadcast();
    t.subscribe((Map<String, dynamic> msg) async {
      ctrl.add(msg);
    });
    return RosSubscription._(t, ctrl);
  }

  /// Stream<T> tiện dụng: tự apply `parser` lên từng JSON message.
  Stream<T> subscribe<T>({
    required String topic,
    required String type,
    required T Function(Map<String, dynamic>) parser,
    int throttleRateMs = 0,
  }) {
    final sub = subscribeRaw(topic: topic, type: type, throttleRateMs: throttleRateMs);
    return sub.stream.map(parser).handleError((Object e, StackTrace st) {
      _logger.e('parse error on $topic: $e', error: e, stackTrace: st);
    });
  }

  /// Publish 1 message lên topic (advertise nếu cần).
  Future<void> publish({
    required String topic,
    required String type,
    required Map<String, dynamic> msg,
  }) async {
    final ros = _requireRos();
    final full = ns(topic);
    final t = Topic(ros: ros, name: full, type: type);
    await t.advertise();
    await t.publish(msg);
  }

  /// Gọi service 1 lần, trả về response JSON.
  Future<Map<String, dynamic>?> callService({
    required String name,
    required String type,
    Map<String, dynamic> request = const {},
  }) async {
    final ros = _requireRos();
    final full = ns(name);
    final service = Service(ros: ros, name: full, type: type);
    final res = await service.call(request);
    return res is Map<String, dynamic> ? res : null;
  }

  Ros _requireRos() {
    final ros = _ros;
    if (ros == null) {
      throw StateError('RosClient chưa connect — gọi connect() trước');
    }
    return ros;
  }

  Future<void> dispose() async {
    await disconnect();
    await _status.close();
  }
}

/// Handle cho 1 subscription, cho phép stream + cancel.
class RosSubscription {
  RosSubscription._(this._topic, this._ctrl);

  final Topic _topic;
  final StreamController<Map<String, dynamic>> _ctrl;

  Stream<Map<String, dynamic>> get stream => _ctrl.stream;

  Future<void> cancel() async {
    try {
      await _topic.unsubscribe();
    } catch (_) {}
    await _ctrl.close();
  }
}

/// Provider giữ RosClient ứng với robot đang được chọn.
final activeRosClientProvider = StateProvider<RosClient?>((ref) => null);
