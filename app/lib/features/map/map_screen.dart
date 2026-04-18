import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/nav2_goals.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

enum _TapMode { goal, initialPose }

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  RosSubscription? _mapSub;
  RosSubscription? _poseSub;
  RosSubscription? _planSub;
  RosSubscription? _scanSub;

  OccupancyGrid? _grid;
  PoseStamped? _robotPose;
  List<Pose> _plan = const [];
  LaserScan? _scan;

  ActionGoalHandle? _activeGoal;
  String? _goalStatusText;

  _TapMode _mode = _TapMode.goal;
  double _zoom = 1.0;
  Offset _pan = Offset.zero;

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
    );
    _mapSub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _grid = OccupancyGrid.fromJson(m));
    });

    _poseSub = client.subscribeRaw(
      topic: RosTopics.amclPose,
      type: RosTypes.poseWithCovariance,
    );
    _poseSub!.stream.listen((m) {
      if (!mounted) return;
      final poseMap = (m['pose'] as Map<String, dynamic>)['pose']
          as Map<String, dynamic>;
      setState(() => _robotPose = PoseStamped(
            Header.fromJson(m['header'] as Map<String, dynamic>),
            Pose.fromJson(poseMap),
          ));
    });

    _planSub = client.subscribeRaw(
      topic: RosTopics.globalPlan,
      type: RosTypes.path,
      throttleRateMs: 200,
    );
    _planSub!.stream.listen((m) {
      if (!mounted) return;
      final poses = (m['poses'] as List?) ?? const [];
      setState(() => _plan = [
            for (final p in poses)
              Pose.fromJson(((p as Map<String, dynamic>)['pose']
                  as Map<String, dynamic>))
          ]);
    });

    _scanSub = client.subscribeRaw(
      topic: RosTopics.scan,
      type: RosTypes.laserScan,
      throttleRateMs: 200,
    );
    _scanSub!.stream.listen((m) {
      if (!mounted) return;
      setState(() => _scan = LaserScan.fromJson(m));
    });
  }

  @override
  void dispose() {
    _mapSub?.cancel();
    _poseSub?.cancel();
    _planSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _sendGoal(double worldX, double worldY) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    await _activeGoal?.cancel();
    setState(() => _goalStatusText = 'Sending goal…');
    final handle = client.sendActionGoal(
      actionName: Nav2Actions.navigateToPose,
      actionType: Nav2Actions.navigateToPoseType,
      goal: Nav2Goals.navigateToPose(x: worldX, y: worldY),
    );
    _activeGoal = handle;
    handle.feedback.listen((fb) {
      final remaining = (fb['distance_remaining'] as num?)?.toDouble();
      if (!mounted) return;
      setState(() => _goalStatusText =
          'Executing… ${remaining != null ? "${remaining.toStringAsFixed(2)} m left" : ""}');
    });
    handle.result.then((res) {
      if (!mounted) return;
      setState(() {
        _goalStatusText = 'Result: ${res.status.name}';
        _activeGoal = null;
      });
    });
  }

  Future<void> _publishInitialPose(double worldX, double worldY) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final msg = {
      'header': const Header(frameId: 'map').toJson(),
      'pose': {
        'pose': Pose(Vector3(worldX, worldY, 0), Quaternion.identity).toJson(),
        'covariance': List<double>.filled(36, 0.0)
          ..[0] = 0.25
          ..[7] = 0.25
          ..[35] = 0.0685,
      },
    };
    client.publish(
      topic: RosTopics.initialPose,
      type: RosTypes.poseWithCovariance,
      msg: msg,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Gửi initialpose: (${worldX.toStringAsFixed(2)}, ${worldY.toStringAsFixed(2)})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = _grid;
    return Column(
      children: [
        _MapToolbar(
          mode: _mode,
          zoom: _zoom,
          status: _goalStatusText,
          onMode: (m) => setState(() => _mode = m),
          onZoom: (v) => setState(() => _zoom = v),
          onCancel: _activeGoal == null
              ? null
              : () async {
                  await _activeGoal?.cancel();
                  if (mounted) {
                    setState(() => _goalStatusText = 'Cancelling…');
                  }
                },
          onRecenter: () => setState(() {
            _pan = Offset.zero;
            _zoom = 1.0;
          }),
        ),
        Expanded(
          child: grid == null
              ? const Center(child: Text('Đang chờ /map …'))
              : LayoutBuilder(
                  builder: (context, c) {
                    final scale = _scaleFor(c, grid);
                    return GestureDetector(
                      onPanUpdate: (d) =>
                          setState(() => _pan += d.delta),
                      onTapUp: (details) {
                        final box =
                            context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final local = box.globalToLocal(details.globalPosition);
                        final offsetX =
                            (c.maxWidth - grid.width * scale) / 2 +
                                _pan.dx;
                        final offsetY =
                            (c.maxHeight - grid.height * scale) / 2 +
                                _pan.dy;
                        final col = (local.dx - offsetX) / scale;
                        final row = (local.dy - offsetY) / scale;
                        final worldX = grid.origin.position.x +
                            col * grid.resolution;
                        final worldY = grid.origin.position.y +
                            (grid.height - row) * grid.resolution;
                        if (_mode == _TapMode.goal) {
                          _sendGoal(worldX, worldY);
                        } else {
                          _publishInitialPose(worldX, worldY);
                        }
                      },
                      child: CustomPaint(
                        painter: _MapPainter(
                          grid: grid,
                          pose: _robotPose,
                          plan: _plan,
                          scan: _scan,
                          zoom: _zoom,
                          pan: _pan,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  double _scaleFor(BoxConstraints c, OccupancyGrid g) {
    final base = math.min(c.maxWidth / g.width, c.maxHeight / g.height);
    return base * _zoom;
  }
}

class _MapToolbar extends StatelessWidget {
  const _MapToolbar({
    required this.mode,
    required this.zoom,
    required this.status,
    required this.onMode,
    required this.onZoom,
    required this.onCancel,
    required this.onRecenter,
  });

  final _TapMode mode;
  final double zoom;
  final String? status;
  final ValueChanged<_TapMode> onMode;
  final ValueChanged<double> onZoom;
  final VoidCallback? onCancel;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SegmentedButton<_TapMode>(
            segments: const [
              ButtonSegment(
                value: _TapMode.goal,
                icon: Icon(Icons.flag_outlined),
                label: Text('Tap → Goal'),
              ),
              ButtonSegment(
                value: _TapMode.initialPose,
                icon: Icon(Icons.gps_fixed),
                label: Text('Tap → InitPose'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onMode(s.first),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.zoom_in),
          SizedBox(
            width: 160,
            child: Slider(
              value: zoom,
              min: 0.5,
              max: 4.0,
              onChanged: onZoom,
            ),
          ),
          Text('${(zoom * 100).toStringAsFixed(0)}%'),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Recenter',
            onPressed: onRecenter,
            icon: const Icon(Icons.center_focus_strong),
          ),
          const Spacer(),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(status!),
                avatar: const Icon(Icons.flag, size: 16),
              ),
            ),
          if (onCancel != null)
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel goal'),
            ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.grid,
    required this.pose,
    required this.plan,
    required this.scan,
    required this.zoom,
    required this.pan,
  });

  final OccupancyGrid grid;
  final PoseStamped? pose;
  final List<Pose> plan;
  final LaserScan? scan;
  final double zoom;
  final Offset pan;

  @override
  void paint(Canvas canvas, Size size) {
    final base =
        math.min(size.width / grid.width, size.height / grid.height);
    final scale = base * zoom;
    final offsetX = (size.width - grid.width * scale) / 2 + pan.dx;
    final offsetY = (size.height - grid.height * scale) / 2 + pan.dy;

    final freePaint = Paint()..color = Colors.white;
    final occPaint = Paint()..color = Colors.black;
    final unkPaint = Paint()..color = Colors.grey.shade400;

    for (var row = 0; row < grid.height; row++) {
      for (var col = 0; col < grid.width; col++) {
        final idx = row * grid.width + col;
        final v = grid.data[idx];
        final paint =
            v == -1 ? unkPaint : (v >= 50 ? occPaint : freePaint);
        final rect = Rect.fromLTWH(
          offsetX + col * scale,
          offsetY + (grid.height - row - 1) * scale,
          scale + 0.5,
          scale + 0.5,
        );
        canvas.drawRect(rect, paint);
      }
    }

    // Global plan
    if (plan.isNotEmpty) {
      final path = Path();
      for (var i = 0; i < plan.length; i++) {
        final p = plan[i];
        final px = offsetX +
            ((p.position.x - grid.origin.position.x) / grid.resolution) *
                scale;
        final py = offsetY +
            (grid.height -
                    (p.position.y - grid.origin.position.y) /
                        grid.resolution) *
                scale;
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Laser scan dots around robot pose
    final p = pose;
    if (p != null && scan != null) {
      final rx = (p.pose.position.x - grid.origin.position.x) /
          grid.resolution;
      final ry = (p.pose.position.y - grid.origin.position.y) /
          grid.resolution;
      final baseX = offsetX + rx * scale;
      final baseY = offsetY + (grid.height - ry) * scale;
      final yaw = p.pose.orientation.yaw;

      final scanPaint = Paint()..color = Colors.redAccent;
      final s = scan!;
      for (var i = 0; i < s.ranges.length; i++) {
        final r = s.ranges[i];
        if (!r.isFinite || r < s.rangeMin || r > s.rangeMax) continue;
        final a = s.angleMin + s.angleIncrement * i + yaw;
        final dx = r * math.cos(a);
        final dy = r * math.sin(a);
        final px = baseX + (dx / grid.resolution) * scale;
        final py = baseY - (dy / grid.resolution) * scale;
        canvas.drawCircle(Offset(px, py), 1.0, scanPaint);
      }
    }

    // Robot pose
    if (p != null) {
      final rx = (p.pose.position.x - grid.origin.position.x) /
          grid.resolution;
      final ry = (p.pose.position.y - grid.origin.position.y) /
          grid.resolution;
      final px = offsetX + rx * scale;
      final py = offsetY + (grid.height - ry) * scale;
      canvas.drawCircle(
          Offset(px, py), 6, Paint()..color = Colors.blueAccent);
      final yaw = p.pose.orientation.yaw;
      canvas.drawLine(
        Offset(px, py),
        Offset(px + math.cos(yaw) * 14, py - math.sin(yaw) * 14),
        Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.grid != grid ||
      old.pose != pose ||
      old.plan != plan ||
      old.scan != scan ||
      old.zoom != zoom ||
      old.pan != pan;
}
