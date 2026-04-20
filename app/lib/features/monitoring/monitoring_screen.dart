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
      final c = ref.read(activeRosClientProvider);
      if (c != null && c.isConnected && mounted) {
        _lastStatus = RosConnectionStatus.connected;
        _wire();
      }
    });
  }

  void _clearSeries() {
    _cpu.clear();
    _gpu.clear();
    _cpuTemp.clear();
    _ram.clear();
    _t = 0;
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
    ref.listen<AsyncValue<RosConnectionStatus>>(
      activeRosStatusProvider,
      (prev, next) {
        final s = next.value ?? RosConnectionStatus.disconnected;
        if (s == _lastStatus) return;
        _lastStatus = s;
        if (s == RosConnectionStatus.connected) {
          _wire();
        } else {
          _sub?.cancel();
          _sub = null;
          _clearSeries();
          setState(() {});
        }
      },
    );

    final client = ref.watch(activeRosClientProvider);
    final status = ref.watch(activeRosStatusProvider).value ??
        client?.currentStatus ??
        RosConnectionStatus.disconnected;
    final online = client != null && status == RosConnectionStatus.connected;

    if (!online) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa kết nối rosbridge',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kết nối robot ở màn Connection, đợi trạng thái Online rồi '
                'mở lại Giám sát. Cần topic ${RosTopics.systemStats} trên robot.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth >= 900 ? 2 : 1;
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: cross,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: cross == 2 ? 1.6 : 1.45,
          children: [
            _ChartCard(
              title: 'CPU %',
              data: _cpu,
              minY: 0,
              maxY: 100,
              color: Colors.teal,
            ),
            _ChartCard(
              title: 'GPU %',
              data: _gpu,
              minY: 0,
              maxY: 100,
              color: Colors.indigo,
            ),
            _ChartCard(
              title: 'RAM %',
              data: _ram,
              minY: 0,
              maxY: 100,
              color: Colors.green,
            ),
            _ChartCard(
              title: 'CPU temp °C',
              data: _cpuTemp,
              minY: 0,
              maxY: 110,
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.data,
    required this.minY,
    required this.maxY,
    required this.color,
  });

  final String title;
  final List<FlSpot> data;
  final double minY;
  final double maxY;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = data.isEmpty ? const [FlSpot(0, 0)] : data;
    double minX = 0;
    double maxX = 1;
    if (data.length >= 2) {
      minX = data.first.x;
      maxX = data.last.x;
      if (maxX <= minX) maxX = minX + 1;
    }

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
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  titlesData: const FlTitlesData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
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
