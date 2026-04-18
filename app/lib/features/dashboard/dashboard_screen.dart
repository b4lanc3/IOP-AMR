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
  RosSubscription? _poseSub;

  BatteryState? _battery;
  Odometry? _odom;
  SystemStats? _stats;
  PoseStamped? _amclPose;

  RosConnectionStatus _lastStatus = RosConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wireIfReady());
  }

  void _wireIfReady() {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    if (client.currentStatus == RosConnectionStatus.connected) _wire();
  }

  void _wire() {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    _batterySub?.cancel();
    _odomSub?.cancel();
    _statsSub?.cancel();
    _poseSub?.cancel();

    _batterySub = client.subscribeRaw(
      topic: RosTopics.battery,
      type: RosTypes.battery,
    );
    _batterySub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _battery = BatteryState.fromJson(m));
    });

    _odomSub = client.subscribeRaw(
      topic: RosTopics.odom,
      type: RosTypes.odometry,
      throttleRateMs: 200,
    );
    _odomSub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _odom = Odometry.fromJson(m));
    });

    _statsSub = client.subscribeRaw(
      topic: RosTopics.systemStats,
      type: RosTypes.systemStats,
    );
    _statsSub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _stats = SystemStats.fromJson(m));
    });

    _poseSub = client.subscribeRaw(
      topic: RosTopics.amclPose,
      type: RosTypes.poseWithCovariance,
      throttleRateMs: 300,
    );
    _poseSub!.stream.listen((m) {
      if (!mounted) return;
      final poseMap = (m['pose'] as Map<String, dynamic>)['pose']
          as Map<String, dynamic>;
      setState(() => _amclPose = PoseStamped(
            Header.fromJson(m['header'] as Map<String, dynamic>),
            Pose.fromJson(poseMap),
          ));
    });
  }

  @override
  void dispose() {
    _batterySub?.cancel();
    _odomSub?.cancel();
    _statsSub?.cancel();
    _poseSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RosConnectionStatus>>(activeRosStatusProvider,
        (prev, next) {
      final s = next.value ?? RosConnectionStatus.disconnected;
      if (s != _lastStatus) {
        _lastStatus = s;
        if (s == RosConnectionStatus.connected) _wire();
      }
    });
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          final cross = (c.maxWidth / 320).floor().clamp(1, 4);
          return GridView.count(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _BatteryCard(battery: _battery),
              _VelocityCard(odom: _odom),
              _PoseCard(odom: _odom, amcl: _amclPose),
              _SystemCard(stats: _stats),
            ],
          );
        },
      ),
    );
  }
}

class _CardBase extends StatelessWidget {
  const _CardBase({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
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
    final pct = (b?.percent ?? 0).clamp(0.0, 100.0);
    final color = pct < 20
        ? Colors.red
        : pct < 50
            ? Colors.orange
            : Colors.green;
    return _CardBase(
      icon: Icons.battery_full,
      title: 'Battery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            b == null ? '—' : '${b.percent.toStringAsFixed(0)} %',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(b == null
              ? '--.- V / --.- A'
              : '${b.voltage.toStringAsFixed(1)} V  |  ${b.current.toStringAsFixed(2)} A'
                  '${b.charging ? "  |  ⚡ charging" : ""}'),
          const Spacer(),
          LinearProgressIndicator(
            value: pct / 100,
            color: color,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
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
    return _CardBase(
      icon: Icons.speed,
      title: 'Velocity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linear:  ${lin.toStringAsFixed(2)} m/s',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Angular: ${ang.toStringAsFixed(2)} rad/s',
              style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          LinearProgressIndicator(
            value: (lin.abs() / 1.5).clamp(0.0, 1.0),
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({required this.odom, required this.amcl});
  final Odometry? odom;
  final PoseStamped? amcl;

  @override
  Widget build(BuildContext context) {
    final p = odom?.pose.position;
    final yaw = odom?.pose.orientation.yaw ?? 0;
    final ap = amcl?.pose.position;
    final ayaw = amcl?.pose.orientation.yaw;
    return _CardBase(
      icon: Icons.place,
      title: 'Pose',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('odom:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text('  x: ${p?.x.toStringAsFixed(2) ?? "—"}  '
              'y: ${p?.y.toStringAsFixed(2) ?? "—"}  '
              'yaw: ${yaw.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          const Text('amcl (map):',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text('  x: ${ap?.x.toStringAsFixed(2) ?? "—"}  '
              'y: ${ap?.y.toStringAsFixed(2) ?? "—"}  '
              'yaw: ${ayaw?.toStringAsFixed(2) ?? "—"}'),
        ],
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
    return _CardBase(
      icon: Icons.memory,
      title: 'Jetson',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('CPU', s?.cpuPercent, 100, '%'),
          _row('GPU', s?.gpuPercent, 100, '%'),
          _row(
              'RAM',
              s == null ? null : (s.ramUsedMb / s.ramTotalMb) * 100,
              100,
              '%'),
          const SizedBox(height: 4),
          Text(
            'Temp CPU/GPU: ${s?.cpuTempC.toStringAsFixed(0) ?? "—"}°C / '
            '${s?.gpuTempC.toStringAsFixed(0) ?? "—"}°C',
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double? value, double max, String unit) {
    final v = value ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 40,
              child:
                  Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: LinearProgressIndicator(
              value: (v / max).clamp(0.0, 1.0),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              value == null ? '—' : '${v.toStringAsFixed(0)}$unit',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
