import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ros/ros_client.dart';
import '../storage/hive_boxes.dart';
import '../storage/models/robot_profile.dart';

/// Giúp switch robot active: disconnect cũ, tạo mới, connect.
class ActiveRobotController {
  ActiveRobotController(this._ref);
  final Ref _ref;

  Future<void> connectTo(RobotProfile profile) async {
    final previous = _ref.read(activeRosClientProvider);
    if (previous != null && previous.profile.id == profile.id) {
      if (!previous.isConnected) await previous.connect();
      return;
    }
    await previous?.dispose();
    final client = RosClient(profile);
    _ref.read(activeRosClientProvider.notifier).state = client;
    await client.connect();
  }

  Future<void> disconnectActive() async {
    final c = _ref.read(activeRosClientProvider);
    await c?.dispose();
    _ref.read(activeRosClientProvider.notifier).state = null;
  }
}

final activeRobotControllerProvider =
    Provider<ActiveRobotController>((ref) => ActiveRobotController(ref));

/// Riverpod provider listing robot profiles. Không dùng ValueListenable trực
/// tiếp vì Hive.watch trả Stream đủ dùng.
final robotProfilesProvider = StreamProvider<List<RobotProfile>>((ref) async* {
  yield HiveBoxes.robots.values.toList(growable: false);
  await for (final _ in HiveBoxes.robots.watch()) {
    yield HiveBoxes.robots.values.toList(growable: false);
  }
});
