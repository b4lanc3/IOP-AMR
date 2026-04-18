import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

import '../../core/gamepad/flydigi_mapper.dart';
import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class TeleopScreen extends ConsumerStatefulWidget {
  const TeleopScreen({super.key});

  @override
  ConsumerState<TeleopScreen> createState() => _TeleopScreenState();
}

class _TeleopScreenState extends ConsumerState<TeleopScreen> {
  final _mapper = FlydigiMapper();
  StreamSubscription<GamepadEvent>? _padSub;
  Timer? _publishTimer;

  // Joystick ảo: stick trái = linear, stick phải = angular
  double _joyLinear = 0;
  double _joyAngular = 0;

  double _maxLinear = 0.5;
  double _maxAngular = 1.2;

  bool _estop = false;

  @override
  void initState() {
    super.initState();
    _padSub = Gamepads.events.listen(_onGamepadEvent);
    _publishTimer = Timer.periodic(const Duration(milliseconds: 67), (_) => _publish()); // ~15 Hz
  }

  void _onGamepadEvent(GamepadEvent event) {
    if (_mapper.update(event)) return;
    final action = FlydigiMapper.detectAction(event);
    if (action == null) return;
    setState(() {
      switch (action) {
        case GamepadAction.toggleEstop:
          _estop = !_estop;
          break;
        case GamepadAction.speedUp:
          _maxLinear = (_maxLinear + 0.05).clamp(0.05, 1.5);
          break;
        case GamepadAction.speedDown:
          _maxLinear = (_maxLinear - 0.05).clamp(0.05, 1.5);
          break;
        default:
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
    } else {
      final gamepadTwist = _mapper.currentTwist();
      final gLin = gamepadTwist.linear.x;
      final gAng = gamepadTwist.angular.z;
      // Nếu gamepad có input thì ưu tiên, ngược lại dùng joystick ảo
      lin = gLin.abs() > 0.01 ? gLin : (-_joyLinear * _maxLinear);
      ang = gAng.abs() > 0.01 ? gAng : (-_joyAngular * _maxAngular);
    }
    await client.publish(
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: Text('E-STOP ${_estop ? "ĐANG BẬT" : ""}'),
                  subtitle: const Text('Dừng toàn bộ chuyển động'),
                  value: _estop,
                  onChanged: (v) => setState(() => _estop = v),
                  secondary: Icon(Icons.stop_circle, color: _estop ? Colors.red : null),
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Text('Max linear: ${_maxLinear.toStringAsFixed(2)} m/s'),
                    Slider(
                      value: _maxLinear,
                      min: 0.05, max: 1.5,
                      onChanged: (v) => setState(() => _maxLinear = v),
                    ),
                    Text('Max angular: ${_maxAngular.toStringAsFixed(2)} rad/s'),
                    Slider(
                      value: _maxAngular,
                      min: 0.1, max: 2.5,
                      onChanged: (v) => setState(() => _maxAngular = v),
                    ),
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
