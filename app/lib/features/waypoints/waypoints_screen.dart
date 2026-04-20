import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/nav2_goals.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/models/waypoint.dart';
import '../../l10n/app_localizations.dart';

class WaypointsScreen extends ConsumerStatefulWidget {
  const WaypointsScreen({super.key});

  @override
  ConsumerState<WaypointsScreen> createState() => _WaypointsScreenState();
}

class _WaypointsScreenState extends ConsumerState<WaypointsScreen> {
  Mission? _selected;
  ActionGoalHandle? _activeGoal;
  String? _progress;
  RosSubscription? _poseSub;
  PoseStamped? _lastPose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _wirePose());
  }

  void _wirePose() {
    final client = ref.read(activeRosClientProvider);
    if (client == null || !client.isConnected) return;
    _poseSub = client.subscribeRaw(
      topic: RosTopics.amclPose,
      type: RosTypes.poseWithCovariance,
      throttleRateMs: 200,
    );
    _poseSub!.stream.listen((m) {
      if (!mounted) return;
      final poseMap = (m['pose'] as Map<String, dynamic>)['pose']
          as Map<String, dynamic>;
      setState(() => _lastPose = PoseStamped(
            Header.fromJson(m['header'] as Map<String, dynamic>),
            Pose.fromJson(poseMap),
          ));
    });
  }

  @override
  void dispose() {
    _poseSub?.cancel();
    super.dispose();
  }

  Future<void> _createMission() async {
    final client = ref.read(activeRosClientProvider);
    final l10n = AppLocalizations.of(context);
    final name = await _askText(l10n.waypointsMissionNameTitle,
        initial: l10n.waypointsMissionNew);
    if (name == null) return;
    final mission = Mission(
      id: const Uuid().v4(),
      name: name,
      robotId: client?.profile.id ?? 'none',
    );
    await HiveBoxes.missions.put(mission.id, mission);
    if (mounted) setState(() => _selected = mission);
  }

  Future<void> _addCurrentPose() async {
    final m = _selected;
    final p = _lastPose;
    if (m == null || p == null) return;
    final l10n = AppLocalizations.of(context);
    final label = await _askText(l10n.waypointsWaypointLabelTitle,
        initial: 'P${m.waypoints.length + 1}');
    m.waypoints.add(Waypoint(
      x: p.pose.position.x,
      y: p.pose.position.y,
      yaw: p.pose.orientation.yaw,
      label: label ?? 'P${m.waypoints.length + 1}',
    ));
    await HiveBoxes.missions.put(m.id, m);
    setState(() {});
  }

  Future<void> _editWaypoint(Mission m, int index) async {
    final w = m.waypoints[index];
    final xCtrl = TextEditingController(text: w.x.toStringAsFixed(2));
    final yCtrl = TextEditingController(text: w.y.toStringAsFixed(2));
    final yawCtrl = TextEditingController(text: w.yaw.toStringAsFixed(2));
    final labelCtrl = TextEditingController(text: w.label);
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.waypointsWaypointTitle(index + 1)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label')),
              TextField(
                  controller: xCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'x (m)')),
              TextField(
                  controller: yCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'y (m)')),
              TextField(
                  controller: yawCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'yaw (rad)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (ok != true) return;
    m.waypoints[index] = Waypoint(
      x: double.tryParse(xCtrl.text) ?? w.x,
      y: double.tryParse(yCtrl.text) ?? w.y,
      yaw: double.tryParse(yawCtrl.text) ?? w.yaw,
      label: labelCtrl.text,
    );
    await HiveBoxes.missions.put(m.id, m);
    setState(() {});
  }

  Future<String?> _askText(String title, {String initial = ''}) async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: Text(l10n.commonOk)),
        ],
      ),
    );
  }

  Future<void> _runMission(Mission m) async {
    final client = ref.read(activeRosClientProvider);
    final l10n = AppLocalizations.of(context);
    if (client == null || m.waypoints.isEmpty) return;
    await _activeGoal?.cancel();
    final goal = Nav2Goals.navigateThroughPoses(
      frameId: m.frameId,
      waypoints: [
        for (final w in m.waypoints) (x: w.x, y: w.y, yaw: w.yaw),
      ],
    );
    setState(
        () => _progress = l10n.waypointsSendingMission(m.waypoints.length));
    final handle = client.sendActionGoal(
      actionName: Nav2Actions.navigateThroughPoses,
      actionType: Nav2Actions.navigateThroughPosesType,
      goal: goal,
    );
    _activeGoal = handle;
    handle.feedback.listen((fb) {
      if (!mounted) return;
      final remaining =
          (fb['number_of_poses_remaining'] as num?)?.toInt();
      setState(() => _progress = remaining != null
          ? l10n.waypointsRunningRemaining(remaining)
          : l10n.waypointsRunning);
    });
    handle.result.then((res) {
      if (!mounted) return;
      setState(() {
        _progress = l10n.mapGoalResult(res.status.name);
        _activeGoal = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final client = ref.watch(activeRosClientProvider);
    final missions = HiveBoxes.missions.values
        .where((m) => client == null || m.robotId == client.profile.id)
        .toList();

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(l10n.waypointsMissions,
                              style: Theme.of(context).textTheme.titleMedium)),
                      IconButton(
                        tooltip: l10n.waypointsNewMissionTooltip,
                        onPressed: _createMission,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final m in missions)
                        ListTile(
                          selected: _selected?.id == m.id,
                          title: Text(m.name),
                          subtitle:
                              Text(l10n.waypointsWaypointCount(m.waypoints.length)),
                          onTap: () => setState(() => _selected = m),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await HiveBoxes.missions.delete(m.id);
                              setState(() {
                                if (_selected?.id == m.id) _selected = null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _missionDetail()),
        ],
      ),
    );
  }

  Widget _missionDetail() {
    final l10n = AppLocalizations.of(context);
    final m = _selected;
    if (m == null) {
      return Center(child: Text(l10n.waypointsSelectMission));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(m.name,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              if (_progress != null)
                Chip(
                    label: Text(_progress!),
                    avatar: const Icon(Icons.flag, size: 16)),
              if (_activeGoal != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    await _activeGoal?.cancel();
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.waypointsCancelNav),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _lastPose == null ? null : _addCurrentPose,
                icon: const Icon(Icons.add_location_alt),
                label: Text(l10n.waypointsAddFromPose),
              ),
              FilledButton.icon(
                onPressed: m.waypoints.isEmpty ? null : () => _runMission(m),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.waypointsRunMission),
              ),
              OutlinedButton.icon(
                onPressed: m.waypoints.isEmpty
                    ? null
                    : () async {
                        m.waypoints.clear();
                        await HiveBoxes.missions.put(m.id, m);
                        setState(() {});
                      },
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.waypointsDeleteAll),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: m.waypoints.isEmpty
                ? Center(
                    child: Text(l10n.waypointsEmptyHint))
                : ReorderableListView.builder(
                    itemCount: m.waypoints.length,
                    onReorder: (oldI, newI) async {
                      if (newI > oldI) newI -= 1;
                      final w = m.waypoints.removeAt(oldI);
                      m.waypoints.insert(newI, w);
                      await HiveBoxes.missions.put(m.id, m);
                      setState(() {});
                    },
                    itemBuilder: (context, i) {
                      final w = m.waypoints[i];
                      return ListTile(
                        key: ValueKey('${m.id}-$i'),
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(
                            w.label.isEmpty ? l10n.waypointsWaypoint : w.label),
                        subtitle: Text(
                            'x=${w.x.toStringAsFixed(2)}  y=${w.y.toStringAsFixed(2)}  yaw=${w.yaw.toStringAsFixed(2)}'),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editWaypoint(m, i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                m.waypoints.removeAt(i);
                                await HiveBoxes.missions.put(m.id, m);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
