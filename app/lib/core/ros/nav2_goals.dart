import 'msg_types.dart';
import 'topics.dart';

/// Helper xây goal cho Nav2 actions.
class Nav2Goals {
  const Nav2Goals._();

  /// Build goal JSON cho `nav2_msgs/action/NavigateToPose`.
  static Map<String, dynamic> navigateToPose({
    required double x,
    required double y,
    double yaw = 0,
    String frameId = 'map',
    String behaviorTree = '',
  }) {
    final pose = PoseStamped(
      Header(frameId: frameId),
      Pose(Vector3(x, y, 0), Quaternion.fromYaw(yaw)),
    );
    return {
      'pose': pose.toJson(),
      'behavior_tree': behaviorTree,
    };
  }

  /// Build goal JSON cho `nav2_msgs/action/NavigateThroughPoses`.
  static Map<String, dynamic> navigateThroughPoses({
    required List<({double x, double y, double yaw})> waypoints,
    String frameId = 'map',
    String behaviorTree = '',
  }) {
    return {
      'poses': [
        for (final w in waypoints)
          PoseStamped(
            Header(frameId: frameId),
            Pose(Vector3(w.x, w.y, 0), Quaternion.fromYaw(w.yaw)),
          ).toJson(),
      ],
      'behavior_tree': behaviorTree,
    };
  }
}

/// Tên action types thường dùng.
class Nav2Actions {
  const Nav2Actions._();
  static const navigateToPose = RosActions.navigateToPose;
  static const navigateThroughPoses = RosActions.navigateThroughPoses;
  static const navigateToPoseType = RosTypes.navigateToPoseAction;
  static const navigateThroughPosesType = RosTypes.navigateThroughPosesAction;
}
