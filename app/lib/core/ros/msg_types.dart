/// Lightweight Dart models cho các ROS message type phổ biến.
///
/// Không dùng `json_serializable` để giữ nhẹ và tường minh — chỉ map JSON từ
/// rosbridge theo đúng tên trường của msg.
library;

import 'dart:math' as math;
import 'dart:typed_data';

class Vector3 {
  final double x;
  final double y;
  final double z;
  const Vector3(this.x, this.y, this.z);

  factory Vector3.fromJson(Map<String, dynamic> json) => Vector3(
        (json['x'] ?? 0).toDouble(),
        (json['y'] ?? 0).toDouble(),
        (json['z'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
  static const zero = Vector3(0, 0, 0);
}

class Quaternion {
  final double x;
  final double y;
  final double z;
  final double w;
  const Quaternion(this.x, this.y, this.z, this.w);

  factory Quaternion.fromJson(Map<String, dynamic> j) => Quaternion(
        (j['x'] ?? 0).toDouble(),
        (j['y'] ?? 0).toDouble(),
        (j['z'] ?? 0).toDouble(),
        (j['w'] ?? 1).toDouble(),
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z, 'w': w};

  /// Chuyển sang yaw (radians) quanh trục Z.
  double get yaw {
    final siny = 2.0 * (w * z + x * y);
    final cosy = 1.0 - 2.0 * (y * y + z * z);
    return math.atan2(siny, cosy);
  }

  static Quaternion fromYaw(double yaw) {
    final half = yaw / 2.0;
    return Quaternion(0, 0, math.sin(half), math.cos(half));
  }

  static const identity = Quaternion(0, 0, 0, 1);
}

class Twist {
  final Vector3 linear;
  final Vector3 angular;
  const Twist(this.linear, this.angular);
  const Twist.zero()
      : linear = Vector3.zero,
        angular = Vector3.zero;

  factory Twist.fromLinAng(double linearX, double angularZ) =>
      Twist(Vector3(linearX, 0, 0), Vector3(0, 0, angularZ));

  Map<String, dynamic> toJson() => {
        'linear': linear.toJson(),
        'angular': angular.toJson(),
      };
}

class Pose {
  final Vector3 position;
  final Quaternion orientation;
  const Pose(this.position, this.orientation);

  factory Pose.fromJson(Map<String, dynamic> j) => Pose(
        Vector3.fromJson(j['position'] as Map<String, dynamic>),
        Quaternion.fromJson(j['orientation'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'position': position.toJson(),
        'orientation': orientation.toJson(),
      };
}

class Header {
  final String frameId;
  final int sec;
  final int nanosec;
  const Header({required this.frameId, this.sec = 0, this.nanosec = 0});

  factory Header.fromJson(Map<String, dynamic> j) {
    final stamp = j['stamp'] as Map<String, dynamic>? ?? const {};
    return Header(
      frameId: (j['frame_id'] ?? '') as String,
      sec: (stamp['sec'] ?? 0) as int,
      nanosec: (stamp['nanosec'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'frame_id': frameId,
        'stamp': {'sec': sec, 'nanosec': nanosec},
      };
}

class PoseStamped {
  final Header header;
  final Pose pose;
  const PoseStamped(this.header, this.pose);

  Map<String, dynamic> toJson() => {
        'header': header.toJson(),
        'pose': pose.toJson(),
      };

  factory PoseStamped.fromJson(Map<String, dynamic> j) => PoseStamped(
        Header.fromJson(j['header'] as Map<String, dynamic>),
        Pose.fromJson(j['pose'] as Map<String, dynamic>),
      );
}

class LaserScan {
  final Header header;
  final double angleMin;
  final double angleMax;
  final double angleIncrement;
  final double rangeMin;
  final double rangeMax;
  final List<double> ranges;
  final List<double> intensities;

  const LaserScan({
    required this.header,
    required this.angleMin,
    required this.angleMax,
    required this.angleIncrement,
    required this.rangeMin,
    required this.rangeMax,
    required this.ranges,
    required this.intensities,
  });

  factory LaserScan.fromJson(Map<String, dynamic> j) => LaserScan(
        header: Header.fromJson(j['header'] as Map<String, dynamic>),
        angleMin: (j['angle_min'] as num).toDouble(),
        angleMax: (j['angle_max'] as num).toDouble(),
        angleIncrement: (j['angle_increment'] as num).toDouble(),
        rangeMin: (j['range_min'] as num).toDouble(),
        rangeMax: (j['range_max'] as num).toDouble(),
        ranges: ((j['ranges'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(growable: false),
        intensities: ((j['intensities'] as List?) ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(growable: false),
      );
}

class OccupancyGrid {
  final Header header;
  final double resolution;
  final int width;
  final int height;
  final Pose origin;
  final Int8List data;

  const OccupancyGrid({
    required this.header,
    required this.resolution,
    required this.width,
    required this.height,
    required this.origin,
    required this.data,
  });

  factory OccupancyGrid.fromJson(Map<String, dynamic> j) {
    final info = j['info'] as Map<String, dynamic>;
    final rawData = j['data'] as List;
    final bytes = Int8List(rawData.length);
    for (var i = 0; i < rawData.length; i++) {
      bytes[i] = (rawData[i] as num).toInt();
    }
    return OccupancyGrid(
      header: Header.fromJson(j['header'] as Map<String, dynamic>),
      resolution: (info['resolution'] as num).toDouble(),
      width: (info['width'] as num).toInt(),
      height: (info['height'] as num).toInt(),
      origin: Pose.fromJson(info['origin'] as Map<String, dynamic>),
      data: bytes,
    );
  }
}

class Odometry {
  final Header header;
  final Pose pose;
  final Twist twist;

  const Odometry({
    required this.header,
    required this.pose,
    required this.twist,
  });

  factory Odometry.fromJson(Map<String, dynamic> j) {
    final poseMap = (j['pose'] as Map<String, dynamic>)['pose']
        as Map<String, dynamic>;
    final twistMap = (j['twist'] as Map<String, dynamic>)['twist']
        as Map<String, dynamic>;
    return Odometry(
      header: Header.fromJson(j['header'] as Map<String, dynamic>),
      pose: Pose.fromJson(poseMap),
      twist: Twist(
        Vector3.fromJson(twistMap['linear'] as Map<String, dynamic>),
        Vector3.fromJson(twistMap['angular'] as Map<String, dynamic>),
      ),
    );
  }
}

class SystemStats {
  final double cpuPercent;
  final double gpuPercent;
  final double ramUsedMb;
  final double ramTotalMb;
  final double cpuTempC;
  final double gpuTempC;
  final double diskUsedGb;
  final double diskTotalGb;

  const SystemStats({
    required this.cpuPercent,
    required this.gpuPercent,
    required this.ramUsedMb,
    required this.ramTotalMb,
    required this.cpuTempC,
    required this.gpuTempC,
    required this.diskUsedGb,
    required this.diskTotalGb,
  });

  factory SystemStats.fromJson(Map<String, dynamic> j) => SystemStats(
        cpuPercent: (j['cpu_percent'] as num?)?.toDouble() ?? 0,
        gpuPercent: (j['gpu_percent'] as num?)?.toDouble() ?? 0,
        ramUsedMb: (j['ram_used_mb'] as num?)?.toDouble() ?? 0,
        ramTotalMb: (j['ram_total_mb'] as num?)?.toDouble() ?? 1,
        cpuTempC: (j['cpu_temp_c'] as num?)?.toDouble() ?? 0,
        gpuTempC: (j['gpu_temp_c'] as num?)?.toDouble() ?? 0,
        diskUsedGb: (j['disk_used_gb'] as num?)?.toDouble() ?? 0,
        diskTotalGb: (j['disk_total_gb'] as num?)?.toDouble() ?? 1,
      );
}

class BatteryState {
  final double voltage;
  final double current;
  final double percent;
  final double temperature;
  final bool charging;

  const BatteryState({
    required this.voltage,
    required this.current,
    required this.percent,
    required this.temperature,
    required this.charging,
  });

  factory BatteryState.fromJson(Map<String, dynamic> j) => BatteryState(
        voltage: (j['voltage'] as num?)?.toDouble() ?? 0,
        current: (j['current'] as num?)?.toDouble() ?? 0,
        percent: (j['percent'] as num?)?.toDouble() ?? 0,
        temperature: (j['temperature'] as num?)?.toDouble() ?? 0,
        charging: (j['charging'] as bool?) ?? false,
      );
}
