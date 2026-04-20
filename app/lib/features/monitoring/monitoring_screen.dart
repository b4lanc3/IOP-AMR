import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  RosSubscription? _sub;
  final _cpu = <FlSpot>[];
  final _gpu = <FlSpot>[];
  final _cpuTemp = <FlSpot>[];
  final _ram = <FlSpot>[];
  int _t = 0;
  static const _max = 60;
  RosConnectionStatus _lastStatus = RosConnectionStatus.disconnected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(activeRosClientProvider);
      if (client != null &&
          client.currentStatus == RosConnectionStatus.connected) {
        _wire();
      }
    });
  }

  void _wire() {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) return;
    _sub?.cancel();
    _sub = client.subscribeRaw(
      topic: RosTopics.systemStats,
      type: RosTypes.systemStats,
      throttleRateMs: 250,
      queueLength: 1,
    );
    _sub!.stream.listen((m) {
      if (!mounted) return;
      final s = SystemStats.fromJson(m);
      final t = (_t++).toDouble();
      setState(() {
        _cpu.add(FlSpot(t, s.cpuPercent));
        _gpu.add(FlSpot(t, s.gpuPercent));
        _cpuTemp.add(FlSpot(t, s.cpuTempC));
        final ramPct =
            s.ramTotalMb > 0 ? (s.ramUsedMb / s.ramTotalMb) * 100 : 0.0;
        _ram.add(FlSpot(t, ramPct));
        _trim(_cpu);
        _trim(_gpu);
        _trim(_cpuTemp);
        _trim(_ram);
      });
    });
  }

  void _trim(List<FlSpot> data) {
    if (data.length > _max) data.removeAt(0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RosConnectionStatus>>(activeRosStatusProvider,
        (prev, next) {
      final s = next.value ?? RosConnectionStatus.disconnected;
      if (s != _lastStatus) {
        _lastStatus = s;
        if (s == RosConnectionStatus.connected) {
          _wire();
        } else {
          _sub?.cancel();
          _sub = null;
        }
      }
    });

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _ChartCard(title: 'CPU %',      data: _cpu,     minY: 0, maxY: 100),
        _ChartCard(title: 'GPU %',      data: _gpu,     minY: 0, maxY: 100),
        _ChartCard(title: 'RAM %',      data: _ram,     minY: 0, maxY: 100),
        _ChartCard(title: 'CPU temp °C',data: _cpuTemp, minY: 0, maxY: 110),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.data,
    required this.minY,
    required this.maxY,
  });

  final String title;
  final List<FlSpot> data;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minY, maxY: maxY,
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.isEmpty ? const [FlSpot(0, 0)] : data,
                      isCurved: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
