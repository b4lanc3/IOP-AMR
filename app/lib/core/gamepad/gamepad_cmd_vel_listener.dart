import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

import '../providers/settings_provider.dart';
import '../ros/msg_types.dart';
import '../ros/ros_client.dart';
import '../ros/topics.dart';
import '../storage/hive_boxes.dart';
import '../storage/models/gamepad_profile.dart';
import 'flydigi_mapper.dart';

/// Điều khiển từ gamepad (Flydigi, v.v.) → `/cmd_vel` khi đã kết nối ROS.
/// Dùng [GamepadNormalizer] để khớp trục trên Windows (GameInput) / Android.
class GamepadCmdVelListener extends ConsumerStatefulWidget {
  const GamepadCmdVelListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GamepadCmdVelListener> createState() =>
      _GamepadCmdVelListenerState();
}

class _GamepadCmdVelListenerState extends ConsumerState<GamepadCmdVelListener>
    with WidgetsBindingObserver {
  late FlydigiMapper _mapper;
  final GamepadNormalizer _normalizer = GamepadNormalizer();
  StreamSubscription<GamepadEvent>? _padSub;

  Timer? _publishTimer;

  bool _estop = false;
  double _linearTrim = 0;

  double _smoothedLin = 0;
  double _smoothedAng = 0;

  static const _smoothTauSec = 0.12;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapper = _buildMapper();
    _padSub = Gamepads.events.listen(_onGamepadEvent);
    _restartPublishTimer(ref.read(appSettingsProvider).teleopPublishHz);
    scheduleMicrotask(_refreshGamepads);
  }

  Future<void> _refreshGamepads() async {
    try {
      await Gamepads.list();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scheduleMicrotask(_refreshGamepads);
    }
  }

  FlydigiMapper _buildMapper() {
    final settings = ref.read(appSettingsProvider);
    final profileId = settings.activeGamepadProfileId;
    final profile = (profileId != null
            ? HiveBoxes.gamepadProfiles.get(profileId)
            : HiveBoxes.gamepadProfiles.values.firstOrNull) ??
        GamepadProfile(id: 'default', name: 'Default');
    return FlydigiMapper(profile);
  }

  void _restartPublishTimer(int hz) {
    _publishTimer?.cancel();
    final periodMs = math.max(1, (1000 / hz).round());
    _publishTimer = Timer.periodic(
      Duration(milliseconds: periodMs),
      (_) => _publish(),
    );
  }

  void _onGamepadAction(GamepadAction action) {
    switch (action) {
      case GamepadAction.toggleEstop:
        setState(() => _estop = !_estop);
      case GamepadAction.speedUp:
        setState(() => _linearTrim = (_linearTrim + 0.05).clamp(-0.3, 0.8));
      case GamepadAction.speedDown:
        setState(() => _linearTrim = (_linearTrim - 0.05).clamp(-0.3, 0.8));
      case GamepadAction.cycleMode:
      case GamepadAction.snapshot:
      case GamepadAction.saveWaypoint:
      case GamepadAction.menu:
      case GamepadAction.home:
        break;
    }
  }

  void _onGamepadEvent(GamepadEvent raw) {
    final normalized = _normalizer.normalize(raw);
    if (normalized.isNotEmpty) {
      for (final e in normalized) {
        if (_mapper.updateNormalized(e)) continue;
        final a = _mapper.detectActionNormalized(e);
        if (a != null) _onGamepadAction(a);
      }
      return;
    }
    if (_mapper.update(raw)) return;
    final a = _mapper.detectAction(raw);
    if (a != null) _onGamepadAction(a);
  }

  void _publish() {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) {
      _smoothedLin = 0;
      _smoothedAng = 0;
      return;
    }

    final settings = ref.read(appSettingsProvider);
    final hz = settings.teleopPublishHz;
    final dt = 1.0 / hz;
    final alpha = 1 - math.exp(-dt / _smoothTauSec);

    final maxLin =
        (settings.defaultMaxLinear + _linearTrim).clamp(0.05, 1.5);
    final maxAng = settings.defaultMaxAngular.clamp(0.1, 2.5);

    double targetLin;
    double targetAng;
    if (_estop) {
      targetLin = 0;
      targetAng = 0;
    } else {
      final g = _mapper.currentTwist(maxLinear: maxLin, maxAngular: maxAng);
      targetLin = g.linear.x;
      targetAng = g.angular.z;
    }

    _smoothedLin += (targetLin - _smoothedLin) * alpha;
    _smoothedAng += (targetAng - _smoothedAng) * alpha;

    if (targetLin.abs() < 0.002 &&
        targetAng.abs() < 0.002 &&
        !_estop) {
      _smoothedLin *= 0.65;
      _smoothedAng *= 0.65;
      if (_smoothedLin.abs() < 0.0008) _smoothedLin = 0;
      if (_smoothedAng.abs() < 0.0008) _smoothedAng = 0;
    }

    client.publish(
      topic: RosTopics.cmdVel,
      type: RosTypes.twist,
      msg: Twist.fromLinAng(_smoothedLin, _smoothedAng).toJson(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _padSub?.cancel();
    _publishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      appSettingsProvider.select((s) => s.teleopPublishHz),
      (_, next) => _restartPublishTimer(next),
    );
    ref.listen<String?>(
      appSettingsProvider.select((s) => s.activeGamepadProfileId),
      (_, __) {
        setState(() {
          _mapper = _buildMapper();
        });
      },
    );
    return widget.child;
  }
}
