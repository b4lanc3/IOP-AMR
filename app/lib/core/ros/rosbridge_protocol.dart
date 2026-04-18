/// Hằng số `op` theo rosbridge v2 protocol.
/// https://github.com/RobotWebTools/rosbridge_suite/blob/ros2/ROSBRIDGE_PROTOCOL.md
library;

class RosbridgeOp {
  const RosbridgeOp._();

  // Outbound (client -> server)
  static const advertise = 'advertise';
  static const unadvertise = 'unadvertise';
  static const publish = 'publish';
  static const subscribe = 'subscribe';
  static const unsubscribe = 'unsubscribe';
  static const callService = 'call_service';
  static const advertiseService = 'advertise_service';
  static const unadvertiseService = 'unadvertise_service';
  static const serviceResponse = 'service_response';
  static const authenticate = 'auth';
  static const sendActionGoal = 'send_action_goal';
  static const cancelActionGoal = 'cancel_action_goal';
  static const advertiseAction = 'advertise_action';
  static const unadvertiseAction = 'unadvertise_action';
  static const actionResult = 'action_result';
  static const actionFeedback = 'action_feedback';
  static const status = 'status';

  static const fragment = 'fragment';
  static const pngCompressed = 'png';
}

/// Trạng thái logic của 1 action goal theo Nav2 / action_msgs/msg/GoalStatus.
/// Khớp bit values của rosbridge status_code từ action result.
enum ActionGoalStatus {
  unknown(0),
  accepted(1),
  executing(2),
  canceling(3),
  succeeded(4),
  canceled(5),
  aborted(6);

  final int code;
  const ActionGoalStatus(this.code);

  static ActionGoalStatus fromCode(int code) {
    for (final s in ActionGoalStatus.values) {
      if (s.code == code) return s;
    }
    return ActionGoalStatus.unknown;
  }

  bool get isTerminal =>
      this == succeeded || this == aborted || this == canceled;
}
