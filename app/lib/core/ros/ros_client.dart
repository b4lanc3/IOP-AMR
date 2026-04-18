import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/models/robot_profile.dart';
import 'rosbridge_client.dart';

export 'rosbridge_client.dart'
    show
        RosConnectionStatus,
        RosSubscription,
        ActionGoalHandle,
        ActionResult;
export 'rosbridge_protocol.dart' show ActionGoalStatus;

/// Wrapper gắn 1 [RobotProfile] với 1 [RosbridgeClient], tự prefix namespace
/// cho mọi topic/service/action.
class RosClient {
  RosClient(this.profile)
      : _bridge = RosbridgeClient(
          profile.websocketUrl,
          options: RosbridgeClientOptions(authToken: profile.authToken),
        );

  final RobotProfile profile;
  final RosbridgeClient _bridge;

  Stream<RosConnectionStatus> get status => _bridge.statusStream;
  RosConnectionStatus get currentStatus => _bridge.status;
  bool get isConnected => _bridge.isConnected;
  String get url => profile.websocketUrl;

  /// Nối tên topic/service/action với namespace.
  String ns(String name) {
    if (profile.namespace.isEmpty) return name;
    final prefix = profile.namespace.startsWith('/')
        ? profile.namespace
        : '/${profile.namespace}';
    if (name.startsWith(prefix)) return name;
    if (!name.startsWith('/')) return '$prefix/$name';
    return '$prefix$name';
  }

  Future<void> connect() => _bridge.connect();
  Future<void> disconnect() => _bridge.disconnect();
  Future<void> dispose() => _bridge.dispose();

  /// Subscribe 1 topic (JSON raw).
  RosSubscription subscribeRaw({
    required String topic,
    required String type,
    int throttleRateMs = 0,
    int queueLength = 1,
  }) =>
      _bridge.subscribe(
        topic: ns(topic),
        type: type,
        throttleRateMs: throttleRateMs,
        queueLength: queueLength,
      );

  /// Subscribe + parse JSON → T.
  Stream<T> subscribe<T>({
    required String topic,
    required String type,
    required T Function(Map<String, dynamic>) parser,
    int throttleRateMs = 0,
  }) {
    final sub = subscribeRaw(
        topic: topic, type: type, throttleRateMs: throttleRateMs);
    return sub.stream.map(parser);
  }

  /// Publish 1 message.
  void publish({
    required String topic,
    required String type,
    required Map<String, dynamic> msg,
  }) =>
      _bridge.publish(topic: ns(topic), type: type, msg: msg);

  /// Gọi service.
  Future<Map<String, dynamic>?> callService({
    required String name,
    required String type,
    Map<String, dynamic> request = const {},
    Duration timeout = const Duration(seconds: 10),
  }) =>
      _bridge.callService(
        name: ns(name),
        type: type,
        request: request,
        timeout: timeout,
      );

  /// Gửi action goal.
  ActionGoalHandle sendActionGoal({
    required String actionName,
    required String actionType,
    required Map<String, dynamic> goal,
    bool wantFeedback = true,
  }) =>
      _bridge.sendActionGoal(
        actionName: ns(actionName),
        actionType: actionType,
        goal: goal,
        wantFeedback: wantFeedback,
      );
}

/// Provider giữ RosClient của robot đang active. Widget watch để lấy client.
final activeRosClientProvider = StateProvider<RosClient?>((ref) => null);

/// Provider stream trạng thái kết nối — tự rebuild UI khi đổi status.
final activeRosStatusProvider = StreamProvider<RosConnectionStatus>((ref) {
  final c = ref.watch(activeRosClientProvider);
  if (c == null) return Stream.value(RosConnectionStatus.disconnected);
  return c.status.distinct();
});
