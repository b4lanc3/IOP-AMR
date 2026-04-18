import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

import '../../core/gamepad/flydigi_mapper.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/models/gamepad_profile.dart';

class TeleopScreen extends ConsumerStatefulWidget {
  const TeleopScreen({super.key});

  @override
  ConsumerState<TeleopScreen> createState() => _TeleopScreenState();
}

class _TeleopScreenState extends ConsumerState<TeleopScreen> {
  late FlydigiMapper _mapper;
  StreamSubscription<GamepadEvent>? _padSub;
  Timer? _publishTimer;

  double _joyLinear = 0;
  double _joyAngular = 0;

  double _maxLinear = 0.5;
  double _maxAngular = 1.2;

  bool _estop = false;
  String _lastSource = 'idle';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _maxLinear = settings.defaultMaxLinear;
    _maxAngular = settings.defaultMaxAngular;

    final profileId = settings.activeGamepadProfileId;
    final profile = (profileId != null
            ? HiveBoxes.gamepadProfiles.get(profileId)
            : HiveBoxes.gamepadProfiles.values.firstOrNull) ??
        GamepadProfile(id: 'default', name: 'Default');
    _mapper = FlydigiMapper(profile);

    _padSub = Gamepads.events.listen(_onGamepadEvent);
    _restartPublishTimer(settings.teleopPublishHz);
  }

  void _restartPublishTimer(int hz) {
    _publishTimer?.cancel();
    final periodMs = (1000 / hz).round();
    _publishTimer = Timer.periodic(
      Duration(milliseconds: periodMs),
      (_) => _publish(),
    );
  }

  void _onGamepadEvent(GamepadEvent event) {
    if (_mapper.update(event)) return;
    final action = _mapper.detectAction(event);
    if (action == null) return;
    setState(() {
      switch (action) {
        case GamepadAction.toggleEstop:
          _estop = !_estop;
        case GamepadAction.speedUp:
          _maxLinear = (_maxLinear + 0.05).clamp(0.05, 1.5);
        case GamepadAction.speedDown:
          _maxLinear = (_maxLinear - 0.05).clamp(0.05, 1.5);
        case GamepadAction.cycleMode:
        case GamepadAction.snapshot:
        case GamepadAction.saveWaypoint:
        case GamepadAction.menu:
        case GamepadAction.home:
          break;
      }
    });
  }

  Future<void> _publish() async {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) return;

    double lin;
    double ang;
    if (_estop) {
      lin = 0;
      ang = 0;
      _lastSource = 'estop';
    } else {
      final g = _mapper.currentTwist(
          maxLinear: _maxLinear, maxAngular: _maxAngular);
      if (g.linear.x.abs() > 0.01 || g.angular.z.abs() > 0.01) {
        lin = g.linear.x;
        ang = g.angular.z;
        _lastSource = 'gamepad';
      } else if (_joyLinear.abs() > 0.01 || _joyAngular.abs() > 0.01) {
        lin = -_joyLinear * _maxLinear;
        ang = -_joyAngular * _maxAngular;
        _lastSource = 'joystick';
      } else {
        lin = 0;
        ang = 0;
        _lastSource = 'idle';
      }
    }
    client.publish(
      topic: RosTopics.cmdVel,
      type: RosTypes.twist,
      msg: Twist.fromLinAng(lin, ang).toJson(),
    );
  }

  @override
  void dispose() {
    _padSub?.cancel();
    _publishTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hz = ref.watch(appSettingsProvider.select((s) => s.teleopPublishHz));
    if (hz != (_publishTimer?.tick != null ? hz : hz)) {
      // Đơn giản hoá: luôn restart khi rebuild — ít chi phí vì Timer tạo nhẹ.
      _restartPublishTimer(hz);
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SwitchListTile(
                  title: Text('E-STOP ${_estop ? "ĐANG BẬT" : ""}'),
                  subtitle: const Text('Dừng toàn bộ chuyển động'),
                  value: _estop,
                  onChanged: (v) => setState(() => _estop = v),
                  secondary: Icon(Icons.stop_circle,
                      color: _estop ? Colors.red : null),
                ),
              ),
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    Text('Max linear: ${_maxLinear.toStringAsFixed(2)} m/s'),
                    Slider(
                      value: _maxLinear,
                      min: 0.05,
                      max: 1.5,
                      onChanged: (v) => setState(() => _maxLinear = v),
                    ),
                    Text(
                        'Max angular: ${_maxAngular.toStringAsFixed(2)} rad/s'),
                    Slider(
                      value: _maxAngular,
                      min: 0.1,
                      max: 2.5,
                      onChanged: (v) => setState(() => _maxAngular = v),
                    ),
                    Text('Source: $_lastSource · $hz Hz',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _JoystickPanel(
                    label: 'Linear (tiến/lùi)',
                    onChanged: (_, y) => setState(() => _joyLinear = y),
                  ),
                ),
                Expanded(
                  child: _JoystickPanel(
                    label: 'Angular (quay)',
                    onChanged: (x, _) => setState(() => _joyAngular = x),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoystickPanel extends StatelessWidget {
  const _JoystickPanel({required this.label, required this.onChanged});

  final String label;
  final void Function(double x, double y) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Joystick(
                  mode: JoystickMode.all,
                  listener: (d) => onChanged(d.x, d.y),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
