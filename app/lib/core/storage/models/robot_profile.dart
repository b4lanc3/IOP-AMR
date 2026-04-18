import 'package:hive/hive.dart';

/// Thông tin 1 robot AMR đã lưu trong Hive.
class RobotProfile {
  final String id;
  String name;
  String host;
  int port;
  String namespace;
  int videoPort;
  bool useSsl;
  String? authToken;

  RobotProfile({
    required this.id,
    required this.name,
    required this.host,
    this.port = 9090,
    this.namespace = '',
    this.videoPort = 8080,
    this.useSsl = false,
    this.authToken,
  });

  String get websocketUrl => '${useSsl ? 'wss' : 'ws'}://$host:$port';

  String videoStreamUrl(String topic) =>
      '${useSsl ? 'https' : 'http'}://$host:$videoPort/stream?topic=$topic&type=mjpeg';

  RobotProfile copyWith({
    String? name,
    String? host,
    int? port,
    String? namespace,
    int? videoPort,
    bool? useSsl,
    String? authToken,
  }) =>
      RobotProfile(
        id: id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        namespace: namespace ?? this.namespace,
        videoPort: videoPort ?? this.videoPort,
        useSsl: useSsl ?? this.useSsl,
        authToken: authToken ?? this.authToken,
      );
}

class RobotProfileAdapter extends TypeAdapter<RobotProfile> {
  @override
  final int typeId = 1;

  @override
  RobotProfile read(BinaryReader reader) {
    final fieldsCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldsCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return RobotProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      host: fields[2] as String,
      port: (fields[3] as int?) ?? 9090,
      namespace: (fields[4] as String?) ?? '',
      videoPort: (fields[5] as int?) ?? 8080,
      useSsl: (fields[6] as bool?) ?? false,
      authToken: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RobotProfile obj) {
    writer.writeByte(8);
    writer.writeByte(0); writer.write(obj.id);
    writer.writeByte(1); writer.write(obj.name);
    writer.writeByte(2); writer.write(obj.host);
    writer.writeByte(3); writer.write(obj.port);
    writer.writeByte(4); writer.write(obj.namespace);
    writer.writeByte(5); writer.write(obj.videoPort);
    writer.writeByte(6); writer.write(obj.useSsl);
    writer.writeByte(7); writer.write(obj.authToken);
  }
}
