import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/ros/ros_client.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/models/waypoint.dart';

class WaypointsScreen extends ConsumerStatefulWidget {
  const WaypointsScreen({super.key});

  @override
  ConsumerState<WaypointsScreen> createState() => _WaypointsScreenState();
}

class _WaypointsScreenState extends ConsumerState<WaypointsScreen> {
  @override
  Widget build(BuildContext context) {
    final client = ref.watch(activeRosClientProvider);
    final missions = HiveBoxes.missions.values
        .where((m) => client == null || m.robotId == client.profile.id)
        .toList();

    return Scaffold(
      body: missions.isEmpty
          ? const Center(child: Text('Chưa có mission nào. Tạo mới bằng nút + bên dưới.'))
          : ListView.builder(
              itemCount: missions.length,
              itemBuilder: (context, i) {
                final m = missions[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(m.name),
                    subtitle: Text('${m.waypoints.length} waypoint · frame ${m.frameId}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Chạy mission',
                          onPressed: () => _runMission(m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await m.delete();
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSample,
        icon: const Icon(Icons.add),
        label: const Text('Tạo mission mẫu'),
      ),
    );
  }

  Future<void> _createSample() async {
    final client = ref.read(activeRosClientProvider);
    final mission = Mission(
      id: const Uuid().v4(),
      name: 'Square patrol',
      robotId: client?.profile.id ?? 'none',
      waypoints: [
        Waypoint(x: 1.0, y: 0.0, label: 'P1'),
        Waypoint(x: 1.0, y: 1.0, label: 'P2'),
        Waypoint(x: 0.0, y: 1.0, label: 'P3'),
        Waypoint(x: 0.0, y: 0.0, label: 'P4'),
      ],
    );
    await HiveBoxes.missions.put(mission.id, mission);
    setState(() {});
  }

  Future<void> _runMission(Mission m) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(
        'TODO: gửi ${m.waypoints.length} waypoint qua /navigate_through_poses (roslibdart chưa support action đầy đủ — sẽ dùng workaround service).',
      )),
    );
  }
}
