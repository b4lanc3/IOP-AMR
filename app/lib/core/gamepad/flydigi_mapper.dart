import 'package:gamepads/gamepads.dart';

import '../ros/msg_types.dart';

/// Config cho mapping gamepad Flydigi Direwolf → hành động.
class GamepadMapping {
  final String linearAxisKey;   // ví dụ 'l.y'
  final String angularAxisKey;  // ví dụ 'r.x'
  final bool invertLinear;
  final bool invertAngular;
  final double linearScale;     // m/s ứng với trục full
  final double angularScale;    // rad/s ứng với trục full
  final double deadzone;

  const GamepadMapping({
    this.linearAxisKey = 'l.y',
    this.angularAxisKey = 'r.x',
    this.invertLinear = true,   // đa số stick Y: up = âm, cần đảo
    this.invertAngular = true,
    this.linearScale = 0.5,
    this.angularScale = 1.2,
    this.deadzone = 0.08,
  });
}

/// Map event thô từ plugin `gamepads` thành `Twist` + các tín hiệu nút.
class FlydigiMapper {
  FlydigiMapper({this.mapping = const GamepadMapping()});

  final GamepadMapping mapping;

  double _linearRaw = 0;
  double _angularRaw = 0;

  /// Cập nhật state từ 1 `GamepadEvent`, trả về true nếu đã có trục thay đổi.
  bool update(GamepadEvent event) {
    if (event.type != KeyType.analog) return false;

    if (event.key == mapping.linearAxisKey) {
      _linearRaw = event.value;
      return true;
    }
    if (event.key == mapping.angularAxisKey) {
      _angularRaw = event.value;
      return true;
    }
    return false;
  }

  Twist currentTwist() {
    double lin = _applyDeadzone(_linearRaw);
    double ang = _applyDeadzone(_angularRaw);
    if (mapping.invertLinear) lin = -lin;
    if (mapping.invertAngular) ang = -ang;
    return Twist.fromLinAng(
      lin * mapping.linearScale,
      ang * mapping.angularScale,
    );
  }

  double _applyDeadzone(double v) =>
      v.abs() < mapping.deadzone ? 0 : v;

  /// Xem nút nào vừa được bấm — trả về tên logic để UI phản ứng.
  static GamepadAction? detectAction(GamepadEvent event) {
    if (event.type != KeyType.button) return null;
    if (event.value < 0.5) return null; // chỉ quan tâm press down
    return switch (event.key) {
      'button-0' => GamepadAction.toggleEstop,
      'button-1' => GamepadAction.cycleMode,
      'button-2' => GamepadAction.snapshot,
      'button-3' => GamepadAction.saveWaypoint,
      'button-4' => GamepadAction.speedDown,
      'button-5' => GamepadAction.speedUp,
      'button-6' => GamepadAction.menu,
      'button-7' => GamepadAction.home,
      _ => null,
    };
  }
}

enum GamepadAction {
  toggleEstop,
  cycleMode,
  snapshot,
  saveWaypoint,
  speedUp,
  speedDown,
  menu,
  home,
}
