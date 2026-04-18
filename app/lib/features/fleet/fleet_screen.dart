import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/models/robot_profile.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> {
  Future<void> _switchTo(RobotProfile profile) async {
    final prev = ref.read(activeRosClientProvider);
    if (prev?.profile.id == profile.id) return;
    await prev?.dispose();
    final client = RosClient(profile);
    ref.read(activeRosClientProvider.notifier).state = client;
    await client.connect();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final robots = HiveBoxes.robots.values.toList();
    final active = ref.watch(activeRosClientProvider);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: robots.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, i) {
        final r = robots[i];
        final isActive = active?.profile.id == r.id;
        return Card(
          child: InkWell(
            onTap: () => _switchTo(r),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.smart_toy_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isActive)
                        const Chip(label: Text('Active'), padding: EdgeInsets.zero),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(r.websocketUrl, style: Theme.of(context).textTheme.bodySmall),
                  Text('ns: ${r.namespace.isEmpty ? "—" : r.namespace}'),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () => _switchTo(r),
                    child: const Text('Chuyển sang robot này'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
