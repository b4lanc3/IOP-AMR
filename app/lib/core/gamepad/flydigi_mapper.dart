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

/// Chuyển key trong profile (SDL-style `l.y` / `r.x`) → trục chuẩn.
GamepadAxis? axisFromProfileKey(String key) {
  switch (key) {
    case 'l.x':
    case 'leftStickX':
      return GamepadAxis.leftStickX;
    case 'l.y':
    case 'leftStickY':
      return GamepadAxis.leftStickY;
    case 'r.x':
    case 'rightStickX':
      return GamepadAxis.rightStickX;
    case 'r.y':
    case 'rightStickY':
      return GamepadAxis.rightStickY;
    case 'leftTrigger':
      return GamepadAxis.leftTrigger;
    case 'rightTrigger':
      return GamepadAxis.rightTrigger;
    default:
      return null;
  }
}

/// Map [GamepadButton] chuẩn → key `button-N` trong [GamepadProfile.buttonActions].
String? legacyButtonKey(GamepadButton b) {
  switch (b) {
    case GamepadButton.a:
      return 'button-0';
    case GamepadButton.b:
      return 'button-1';
    case GamepadButton.x:
      return 'button-2';
    case GamepadButton.y:
      return 'button-3';
    case GamepadButton.leftBumper:
      return 'button-4';
    case GamepadButton.rightBumper:
      return 'button-5';
    case GamepadButton.back:
      return 'button-6';
    case GamepadButton.start:
      return 'button-7';
    case GamepadButton.leftStick:
      return 'button-8';
    case GamepadButton.rightStick:
      return 'button-9';
    case GamepadButton.leftTrigger:
    case GamepadButton.rightTrigger:
    case GamepadButton.home:
    case GamepadButton.dpadUp:
    case GamepadButton.dpadDown:
    case GamepadButton.dpadLeft:
    case GamepadButton.dpadRight:
    case GamepadButton.touchpad:
      return null;
  }
}

/// Map event từ plugin `gamepads` (raw + normalized) thành [Twist] + nút.
class FlydigiMapper {
  FlydigiMapper(this.profile);
  GamepadProfile profile;

  double _linearRaw = 0;
  double _angularRaw = 0;

  void updateProfile(GamepadProfile next) {
    profile = next;
  }

  GamepadAxis? get _linearAxis => axisFromProfileKey(profile.linearAxisKey);
  GamepadAxis? get _angularAxis => axisFromProfileKey(profile.angularAxisKey);

  /// Raw (Android / fallback) — key khớp trực tiếp profile.
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

  /// Windows / iOS / … — sau [GamepadNormalizer], dùng [GamepadAxis].
  bool updateNormalized(NormalizedGamepadEvent event) {
    if (event.axis == null) return false;
    final la = _linearAxis;
    final aa = _angularAxis;
    if (la != null && event.axis == la) {
      _linearRaw = event.value;
      return true;
    }
    if (aa != null && event.axis == aa) {
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

  GamepadAction? detectAction(GamepadEvent event) {
    if (event.type != KeyType.button) return null;
    if (event.value < 0.5) return null;
    final name = profile.buttonActions[event.key];
    if (name == null) return null;
    return _parseAction(name);
  }

  GamepadAction? detectActionNormalized(NormalizedGamepadEvent event) {
    if (event.button == null) return null;
    if (event.value < 0.5) return null;
    final key = legacyButtonKey(event.button!);
    if (key == null) return null;
    final name = profile.buttonActions[key];
    if (name == null) return null;
    return _parseAction(name);
  }
}
