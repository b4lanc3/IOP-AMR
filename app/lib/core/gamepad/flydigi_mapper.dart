import 'package:gamepads/gamepads.dart';

import '../ros/msg_types.dart';
import '../storage/models/gamepad_profile.dart';

/// Action enum — tên logic để UI bind.
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

GamepadAction? _parseAction(String name) {
  for (final a in GamepadAction.values) {
    if (a.name == name) return a;
  }
  return null;
}

/// Map event thô từ plugin `gamepads` thành `Twist` + các tín hiệu nút.
class FlydigiMapper {
  FlydigiMapper(this.profile);
  GamepadProfile profile;

  double _linearRaw = 0;
  double _angularRaw = 0;

  void updateProfile(GamepadProfile next) {
    profile = next;
  }

  /// Cập nhật state từ 1 [GamepadEvent], trả về true nếu đã có trục thay đổi.
  bool update(GamepadEvent event) {
    if (event.type != KeyType.analog) return false;
    if (event.key == profile.linearAxisKey) {
      _linearRaw = event.value;
      return true;
    }
    if (event.key == profile.angularAxisKey) {
      _angularRaw = event.value;
      return true;
    }
    return false;
  }

  Twist currentTwist({double? maxLinear, double? maxAngular}) {
    final lMax = maxLinear ?? profile.linearScale;
    final aMax = maxAngular ?? profile.angularScale;
    double lin = _applyDeadzone(_linearRaw);
    double ang = _applyDeadzone(_angularRaw);
    if (profile.invertLinear) lin = -lin;
    if (profile.invertAngular) ang = -ang;
    return Twist.fromLinAng(lin * lMax, ang * aMax);
  }

  double _applyDeadzone(double v) =>
      v.abs() < profile.deadzone ? 0 : v;

  /// Nếu button event → trả về action tương ứng.
  GamepadAction? detectAction(GamepadEvent event) {
    if (event.type != KeyType.button) return null;
    if (event.value < 0.5) return null;
    final name = profile.buttonActions[event.key];
    if (name == null) return null;
    return _parseAction(name);
  }
}
