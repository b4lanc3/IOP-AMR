/// Tên topic / service / action cố định, đồng bộ với /docs/PROTOCOL.md.
class RosTopics {
  const RosTopics._();

  // Subscribe (robot -> app)
  static const scan = '/scan';
  static const map = '/map';
  static const odom = '/odom';
  static const amclPose = '/amcl_pose';
  static const tf = '/tf';
  static const tfStatic = '/tf_static';
  static const jointStates = '/joint_states';
  static const globalPlan = '/plan';
  static const localPlan = '/local_plan';
  static const systemStats = '/amr/system_stats';
  static const battery = '/amr/battery';

  // Publish (app -> robot)
  static const cmdVel = '/cmd_vel';
  static const initialPose = '/initialpose';
}

class RosServices {
  const RosServices._();

  static const saveMap = '/slam_toolbox/save_map';
  static const slamControl = '/amr/slam/control';
  static const estop = '/amr/estop';
  static const bagControl = '/amr/bag/control';
  static const joyStack = '/amr/joy_stack';

  static String getParameters(String node) => '$node/get_parameters';
  static String setParameters(String node) => '$node/set_parameters';
}

class RosActions {
  const RosActions._();

  static const navigateToPose = '/navigate_to_pose';
  static const navigateThroughPoses = '/navigate_through_poses';
}

class RosTypes {
  const RosTypes._();

  // std_msgs / sensor_msgs / nav_msgs / geometry_msgs / tf2_msgs
  static const twist = 'geometry_msgs/msg/Twist';
  static const pose = 'geometry_msgs/msg/Pose';
  static const poseStamped = 'geometry_msgs/msg/PoseStamped';
  static const poseWithCovariance =
      'geometry_msgs/msg/PoseWithCovarianceStamped';
  static const laserScan = 'sensor_msgs/msg/LaserScan';
  static const occupancyGrid = 'nav_msgs/msg/OccupancyGrid';
  static const odometry = 'nav_msgs/msg/Odometry';
  static const path = 'nav_msgs/msg/Path';
  static const jointState = 'sensor_msgs/msg/JointState';
  static const tfMessage = 'tf2_msgs/msg/TFMessage';

  // Custom
  static const systemStats = 'amr_integration/msg/SystemStats';
  static const battery = 'amr_integration/msg/Battery';

  // Service
  static const estopSrv = 'amr_integration/srv/EStop';
  static const bagControlSrv = 'amr_integration/srv/BagControl';
  static const slamControlSrv = 'amr_integration/srv/SlamControl';
  static const joyStackSrv = 'amr_integration/srv/JoyStackControl';
  static const saveMapSrv = 'slam_toolbox/srv/SaveMap';
  static const setParamsSrv = 'rcl_interfaces/srv/SetParameters';
  static const getParamsSrv = 'rcl_interfaces/srv/GetParameters';

  // Action
  static const navigateToPoseAction = 'nav2_msgs/action/NavigateToPose';
  static const navigateThroughPosesAction =
      'nav2_msgs/action/NavigateThroughPoses';
}
