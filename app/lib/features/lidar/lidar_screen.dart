import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  double _scale = 60.0; // pixels per metre

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
    )..stream.listen((m) => setState(() => _scan = LaserScan.fromJson(m)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.zoom_in),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: 10, max: 200,
                  label: '${_scale.toStringAsFixed(0)} px/m',
                  onChanged: (v) => setState(() => _scale = v),
                ),
              ),
              Text('${_scale.toStringAsFixed(0)} px/m'),
            ],
          ),
        ),
        Expanded(
          child: CustomPaint(
            painter: _LaserPainter(scan: _scan, pxPerMetre: _scale),
            child: Container(),
          ),
        ),
      ],
    );
  }
}

class _LaserPainter extends CustomPainter {
  _LaserPainter({required this.scan, required this.pxPerMetre});

  final LaserScan? scan;
  final double pxPerMetre;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Grid
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (var r = 1; r <= 10; r++) {
      canvas.drawCircle(Offset(cx, cy), r * pxPerMetre, gridPaint);
    }
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), gridPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), gridPaint);

    // Robot
    final robotPaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(Offset(cx, cy), 6, robotPaint);
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + 14, cy),
      Paint()..color = Colors.blueAccent..strokeWidth = 2,
    );

    final s = scan;
    if (s == null) return;

    final pointPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    for (var i = 0; i < s.ranges.length; i++) {
      final r = s.ranges[i];
      if (!r.isFinite || r < s.rangeMin || r > s.rangeMax) continue;
      final a = s.angleMin + s.angleIncrement * i;
      // Trong frame LaserScan: x forward, y left → map sang canvas (y up)
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      final px = cx + x * pxPerMetre;
      final py = cy - y * pxPerMetre;
      canvas.drawCircle(Offset(px, py), 1.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LaserPainter old) =>
      old.scan != scan || old.pxPerMetre != pxPerMetre;
}
