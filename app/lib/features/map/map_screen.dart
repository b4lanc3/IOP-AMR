import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  RosSubscription? _mapSub;
  RosSubscription? _poseSub;
  OccupancyGrid? _grid;
  PoseStamped? _robotPose;

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wire());
  }

  void _wire() {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) return;

    _mapSub = client.subscribeRaw(
      topic: RosTopics.map,
      type: RosTypes.occupancyGrid,
    )..stream.listen((m) => setState(() => _grid = OccupancyGrid.fromJson(m)));

    _poseSub = client.subscribeRaw(
      topic: RosTopics.amclPose,
      type: RosTypes.poseWithCovariance,
    )..stream.listen((m) {
        final poseMap = (m['pose'] as Map<String, dynamic>)['pose'] as Map<String, dynamic>;
        setState(() => _robotPose = PoseStamped(
              Header.fromJson(m['header'] as Map<String, dynamic>),
              Pose.fromJson(poseMap),
            ));
      });
  }

  @override
  void dispose() {
    _mapSub?.cancel();
    _poseSub?.cancel();
    super.dispose();
  }

  Future<void> _sendGoal(double worldX, double worldY) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    setState(() => _sending = true);
    try {
      // TODO: Chuyển sang call action /navigate_to_pose (action client).
      // Dùng tạm topic goal_pose (Nav2 cũng accept) để mock flow.
      final goal = PoseStamped(
        const Header(frameId: 'map'),
        Pose(
          Vector3(worldX, worldY, 0),
          Quaternion.identity,
        ),
      );
      await client.publish(
        topic: '/goal_pose',
        type: RosTypes.poseStamped,
        msg: goal.toJson(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi goal: (${worldX.toStringAsFixed(2)}, ${worldY.toStringAsFixed(2)})')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grid = _grid;
    if (grid == null) {
      return const Center(child: Text('Đang chờ /map …'));
    }
    return LayoutBuilder(
      builder: (context, c) {
        final scale = math.min(
          c.maxWidth / grid.width,
          c.maxHeight / grid.height,
        );
        return GestureDetector(
          onTapUp: _sending
              ? null
              : (details) {
                  // Chuyển điểm tap (pixel) → thế giới (m).
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = box.globalToLocal(details.globalPosition);
                  final centerX = c.maxWidth / 2;
                  final centerY = c.maxHeight / 2;
                  final pxX = local.dx - (centerX - grid.width * scale / 2);
                  final pxY = local.dy - (centerY - grid.height * scale / 2);
                  final col = pxX / scale;
                  final row = pxY / scale;
                  // Trong OccupancyGrid: data row-major, origin (0,0) ở góc dưới-trái.
                  final worldX = grid.origin.position.x + col * grid.resolution;
                  final worldY = grid.origin.position.y +
                      (grid.height - row) * grid.resolution;
                  _sendGoal(worldX, worldY);
                },
          child: CustomPaint(
            painter: _MapPainter(grid: grid, pose: _robotPose),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.grid, this.pose});

  final OccupancyGrid grid;
  final PoseStamped? pose;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / grid.width, size.height / grid.height);
    final offsetX = (size.width - grid.width * scale) / 2;
    final offsetY = (size.height - grid.height * scale) / 2;

    final freePaint = Paint()..color = Colors.white;
    final occPaint = Paint()..color = Colors.black;
    final unkPaint = Paint()..color = Colors.grey.shade400;

    for (var row = 0; row < grid.height; row++) {
      for (var col = 0; col < grid.width; col++) {
        final idx = row * grid.width + col;
        final v = grid.data[idx];
        final paint = v == -1 ? unkPaint : (v >= 50 ? occPaint : freePaint);
        final rect = Rect.fromLTWH(
          offsetX + col * scale,
          offsetY + (grid.height - row - 1) * scale,
          scale + 0.5,
          scale + 0.5,
        );
        canvas.drawRect(rect, paint);
      }
    }

    // Robot pose
    final p = pose;
    if (p != null) {
      final rx = (p.pose.position.x - grid.origin.position.x) / grid.resolution;
      final ry = (p.pose.position.y - grid.origin.position.y) / grid.resolution;
      final px = offsetX + rx * scale;
      final py = offsetY + (grid.height - ry) * scale;
      canvas.drawCircle(Offset(px, py), 6, Paint()..color = Colors.blueAccent);
      final yaw = p.pose.orientation.yaw;
      canvas.drawLine(
        Offset(px, py),
        Offset(px + math.cos(yaw) * 14, py - math.sin(yaw) * 14),
        Paint()..color = Colors.blueAccent..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.grid != grid || old.pose != pose;
}
