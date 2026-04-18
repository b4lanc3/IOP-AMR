import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class LidarScreen extends ConsumerStatefulWidget {
  const LidarScreen({super.key});

  @override
  ConsumerState<LidarScreen> createState() => _LidarScreenState();
}

class _LidarScreenState extends ConsumerState<LidarScreen> {
  RosSubscription? _sub;
  LaserScan? _scan;
  double _scale = 60.0;
  Offset _pan = Offset.zero;
  double _rangeMax = 10.0;
  double _rangeMin = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) return;
    _sub = client.subscribeRaw(
      topic: RosTopics.scan,
      type: RosTypes.laserScan,
      throttleRateMs: 100,
    );
    _sub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _scan = LaserScan.fromJson(m));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showGrid =
        ref.watch(appSettingsProvider.select((s) => s.showGridOnLidar));
    return Column(
      children: [
        _LidarToolbar(
          scale: _scale,
          rangeMin: _rangeMin,
          rangeMax: _rangeMax,
          onScale: (v) => setState(() => _scale = v),
          onRangeMin: (v) => setState(() => _rangeMin = v),
          onRangeMax: (v) => setState(() => _rangeMax = v),
          onReset: () => setState(() {
            _pan = Offset.zero;
            _scale = 60.0;
          }),
        ),
        Expanded(
          child: GestureDetector(
            onPanUpdate: (d) => setState(() => _pan += d.delta),
            child: CustomPaint(
              painter: _LaserPainter(
                scan: _scan,
                pxPerMetre: _scale,
                pan: _pan,
                showGrid: showGrid,
                rangeMin: _rangeMin,
                rangeMax: _rangeMax,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LidarToolbar extends StatelessWidget {
  const _LidarToolbar({
    required this.scale,
    required this.rangeMin,
    required this.rangeMax,
    required this.onScale,
    required this.onRangeMin,
    required this.onRangeMax,
    required this.onReset,
  });

  final double scale;
  final double rangeMin;
  final double rangeMax;
  final ValueChanged<double> onScale;
  final ValueChanged<double> onRangeMin;
  final ValueChanged<double> onRangeMax;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.zoom_in),
          Expanded(
            child: Slider(
              value: scale,
              min: 10,
              max: 200,
              label: '${scale.toStringAsFixed(0)} px/m',
              onChanged: onScale,
            ),
          ),
          Text('${scale.toStringAsFixed(0)} px/m'),
          const SizedBox(width: 16),
          const Text('Range'),
          SizedBox(
            width: 240,
            child: RangeSlider(
              min: 0,
              max: 30,
              divisions: 30,
              values: RangeValues(rangeMin, rangeMax),
              labels: RangeLabels(
                '${rangeMin.toStringAsFixed(1)}m',
                '${rangeMax.toStringAsFixed(1)}m',
              ),
              onChanged: (v) {
                onRangeMin(v.start);
                onRangeMax(v.end);
              },
            ),
          ),
          IconButton(
            tooltip: 'Reset view',
            onPressed: onReset,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }
}

class _LaserPainter extends CustomPainter {
  _LaserPainter({
    required this.scan,
    required this.pxPerMetre,
    required this.pan,
    required this.showGrid,
    required this.rangeMin,
    required this.rangeMax,
  });

  final LaserScan? scan;
  final double pxPerMetre;
  final Offset pan;
  final bool showGrid;
  final double rangeMin;
  final double rangeMax;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + pan.dx;
    final cy = size.height / 2 + pan.dy;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..strokeWidth = 1;
      for (var r = 1; r <= 15; r++) {
        canvas.drawCircle(Offset(cx, cy), r * pxPerMetre, gridPaint);
      }
      canvas.drawLine(Offset(0, cy), Offset(size.width, cy), gridPaint);
      canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), gridPaint);
    }

    // Robot
    final robotPaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(Offset(cx, cy), 6, robotPaint);
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + 14, cy),
      Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 2,
    );

    final s = scan;
    if (s == null) return;

    final pointPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    final lineToPoint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final effMin = math.max(rangeMin, s.rangeMin);
    final effMax = math.min(rangeMax, s.rangeMax);

    for (var i = 0; i < s.ranges.length; i++) {
      final r = s.ranges[i];
      if (!r.isFinite || r < effMin || r > effMax) continue;
      final a = s.angleMin + s.angleIncrement * i;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      final px = cx + x * pxPerMetre;
      final py = cy - y * pxPerMetre;
      canvas.drawLine(Offset(cx, cy), Offset(px, py), lineToPoint);
      canvas.drawCircle(Offset(px, py), 1.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LaserPainter old) =>
      old.scan != scan ||
      old.pxPerMetre != pxPerMetre ||
      old.pan != pan ||
      old.showGrid != showGrid ||
      old.rangeMin != rangeMin ||
      old.rangeMax != rangeMax;
}
