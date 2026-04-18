import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  RosSubscription? _batterySub;
  RosSubscription? _odomSub;
  RosSubscription? _statsSub;

  BatteryState? _battery;
  Odometry? _odom;
  SystemStats? _stats;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) return;

    _batterySub = client.subscribeRaw(
      topic: RosTopics.battery,
      type: RosTypes.battery,
    )..stream.listen((m) {
        setState(() => _battery = BatteryState.fromJson(m));
      });

    _odomSub = client.subscribeRaw(
      topic: RosTopics.odom,
      type: RosTypes.odometry,
      throttleRateMs: 200,
    )..stream.listen((m) {
        setState(() => _odom = Odometry.fromJson(m));
      });

    _statsSub = client.subscribeRaw(
      topic: RosTopics.systemStats,
      type: RosTypes.systemStats,
    )..stream.listen((m) {
        setState(() => _stats = SystemStats.fromJson(m));
      });
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    _odomSub?.cancel();
    _statsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final cross = (c.maxWidth / 320).floor().clamp(1, 4);
          return GridView.count(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _BatteryCard(battery: _battery),
              _VelocityCard(odom: _odom),
              _PoseCard(odom: _odom),
              _SystemCard(stats: _stats),
            ],
          );
        },
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.battery});
  final BatteryState? battery;

  @override
  Widget build(BuildContext context) {
    final b = battery;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.battery_full),
              SizedBox(width: 8),
              Text('Battery', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const Spacer(),
            Text(
              b == null ? '—' : '${b.percent.toStringAsFixed(0)} %',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(b == null
                ? '--.- V / --.- A'
                : '${b.voltage.toStringAsFixed(1)} V  |  ${b.current.toStringAsFixed(2)} A${b.charging ? " (charging)" : ""}'),
            if (b != null)
              LinearProgressIndicator(
                value: (b.percent / 100).clamp(0, 1),
              ),
          ],
        ),
      ),
    );
  }
}

class _VelocityCard extends StatelessWidget {
  const _VelocityCard({required this.odom});
  final Odometry? odom;

  @override
  Widget build(BuildContext context) {
    final lin = odom?.twist.linear.x ?? 0;
    final ang = odom?.twist.angular.z ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.speed),
              SizedBox(width: 8),
              Text('Velocity', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const Spacer(),
            Text('Linear:  ${lin.toStringAsFixed(2)} m/s'),
            Text('Angular: ${ang.toStringAsFixed(2)} rad/s'),
          ],
        ),
      ),
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({required this.odom});
  final Odometry? odom;

  @override
  Widget build(BuildContext context) {
    final p = odom?.pose.position;
    final yaw = odom?.pose.orientation.yaw ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.place),
              SizedBox(width: 8),
              Text('Pose (odom)', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const Spacer(),
            Text('x: ${p?.x.toStringAsFixed(2) ?? "—"} m'),
            Text('y: ${p?.y.toStringAsFixed(2) ?? "—"} m'),
            Text('yaw: ${yaw.toStringAsFixed(2)} rad'),
          ],
        ),
      ),
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({required this.stats});
  final SystemStats? stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.memory),
              SizedBox(width: 8),
              Text('System', style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const Spacer(),
            Text('CPU: ${s?.cpuPercent.toStringAsFixed(0) ?? "—"}%   |   GPU: ${s?.gpuPercent.toStringAsFixed(0) ?? "—"}%'),
            Text('RAM: ${s == null ? "—" : "${s.ramUsedMb.toStringAsFixed(0)} / ${s.ramTotalMb.toStringAsFixed(0)} MB"}'),
            Text('Temp CPU/GPU: ${s?.cpuTempC.toStringAsFixed(0) ?? "—"}°C / ${s?.gpuTempC.toStringAsFixed(0) ?? "—"}°C'),
          ],
        ),
      ),
    );
  }
}
