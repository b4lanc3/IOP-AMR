import 'package:hive/hive.dart';

/// Cấu hình mapping 1 gamepad.
class GamepadProfile {
  String id;
  String name;
  String linearAxisKey;
  String angularAxisKey;
  bool invertLinear;
  bool invertAngular;
  double linearScale;
  double angularScale;
  double deadzone;
  Map<String, String> buttonActions; // key 'button-0' -> action name

  GamepadProfile({
    required this.id,
    required this.name,
    this.linearAxisKey = 'l.y',
    this.angularAxisKey = 'r.x',
    this.invertLinear = true,
    this.invertAngular = true,
    this.linearScale = 0.5,
    this.angularScale = 1.2,
    this.deadzone = 0.08,
    Map<String, String>? buttonActions,
  }) : buttonActions = buttonActions ?? _defaultButtons();

  static Map<String, String> _defaultButtons() => {
        'button-0': 'toggleEstop',
        'button-1': 'cycleMode',
        'button-2': 'snapshot',
        'button-3': 'saveWaypoint',
        'button-4': 'speedDown',
        'button-5': 'speedUp',
        'button-6': 'menu',
        'button-7': 'home',
      };
}

class GamepadProfileAdapter extends TypeAdapter<GamepadProfile> {
  @override
  final int typeId = 11;

  @override
  GamepadProfile read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) {
      f[r.readByte()] = r.read();
    }
    return GamepadProfile(
      id: f[0] as String,
      name: f[1] as String,
      linearAxisKey: (f[2] as String?) ?? 'l.y',
      angularAxisKey: (f[3] as String?) ?? 'r.x',
      invertLinear: (f[4] as bool?) ?? true,
      invertAngular: (f[5] as bool?) ?? true,
      linearScale: ((f[6] as num?) ?? 0.5).toDouble(),
      angularScale: ((f[7] as num?) ?? 1.2).toDouble(),
      deadzone: ((f[8] as num?) ?? 0.08).toDouble(),
      buttonActions:
          ((f[9] as Map?) ?? const {}).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter w, GamepadProfile o) {
    w.writeByte(10);
    w.writeByte(0); w.write(o.id);
    w.writeByte(1); w.write(o.name);
    w.writeByte(2); w.write(o.linearAxisKey);
    w.writeByte(3); w.write(o.angularAxisKey);
    w.writeByte(4); w.write(o.invertLinear);
    w.writeByte(5); w.write(o.invertAngular);
    w.writeByte(6); w.write(o.linearScale);
    w.writeByte(7); w.write(o.angularScale);
    w.writeByte(8); w.write(o.deadzone);
    w.writeByte(9); w.write(o.buttonActions);
  }
}
