import 'package:hive/hive.dart';

class Waypoint {
  final double x;
  final double y;
  final double yaw;
  final String label;

  Waypoint({
    required this.x,
    required this.y,
    this.yaw = 0,
    this.label = '',
  });
}

class Mission {
  final String id;
  String name;
  String robotId;
  String frameId;
  DateTime createdAt;
  List<Waypoint> waypoints;

  Mission({
    required this.id,
    required this.name,
    required this.robotId,
    this.frameId = 'map',
    DateTime? createdAt,
    List<Waypoint>? waypoints,
  })  : createdAt = createdAt ?? DateTime.now(),
        waypoints = waypoints ?? [];
}

class WaypointAdapter extends TypeAdapter<Waypoint> {
  @override
  final int typeId = 2;

  @override
  Waypoint read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) {
      f[r.readByte()] = r.read();
    }
    return Waypoint(
      x: (f[0] as num).toDouble(),
      y: (f[1] as num).toDouble(),
      yaw: ((f[2] as num?) ?? 0).toDouble(),
      label: (f[3] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter w, Waypoint o) {
    w.writeByte(4);
    w.writeByte(0); w.write(o.x);
    w.writeByte(1); w.write(o.y);
    w.writeByte(2); w.write(o.yaw);
    w.writeByte(3); w.write(o.label);
  }
}

class MissionAdapter extends TypeAdapter<Mission> {
  @override
  final int typeId = 3;

  @override
  Mission read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) {
      f[r.readByte()] = r.read();
    }
    return Mission(
      id: f[0] as String,
      name: f[1] as String,
      robotId: f[2] as String,
      frameId: (f[3] as String?) ?? 'map',
      createdAt: f[4] as DateTime? ?? DateTime.now(),
      waypoints: ((f[5] as List?) ?? const []).cast<Waypoint>(),
    );
  }

  @override
  void write(BinaryWriter w, Mission o) {
    w.writeByte(6);
    w.writeByte(0); w.write(o.id);
    w.writeByte(1); w.write(o.name);
    w.writeByte(2); w.write(o.robotId);
    w.writeByte(3); w.write(o.frameId);
    w.writeByte(4); w.write(o.createdAt);
    w.writeByte(5); w.write(o.waypoints);
  }
}
