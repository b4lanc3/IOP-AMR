import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final _bagName = TextEditingController(text: 'bag_${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
  final _topics = TextEditingController(text: '/scan,/odom,/tf,/camera/color/image_raw');
  List<String> _bags = [];
  bool _recording = false;

  Future<void> _call(String action) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final req = {
      'action': action,
      'bag_name': _bagName.text.trim(),
      'topics': _topics.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };
    final res = await client.callService(
      name: RosServices.bagControl,
      type: RosTypes.bagControlSrv,
      request: req,
    );
    if (!mounted) return;
    setState(() {
      if (action == 'start') _recording = true;
      if (action == 'stop') _recording = false;
      _bags = ((res?['bags'] as List?) ?? const []).cast<String>();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bag $action: ${res?['message'] ?? "sent"}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rosbag recorder', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(
            controller: _bagName,
            decoration: const InputDecoration(labelText: 'Bag name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topics,
            decoration: const InputDecoration(
              labelText: 'Topics (phẩy phân cách)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _recording ? null : () => _call('start'),
                icon: const Icon(Icons.fiber_manual_record),
                label: const Text('Start'),
              ),
              FilledButton.tonalIcon(
                onPressed: _recording ? () => _call('stop') : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
              OutlinedButton.icon(
                onPressed: () => _call('list'),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('Bags có sẵn', style: Theme.of(context).textTheme.titleMedium),
          Expanded(
            child: _bags.isEmpty
                ? const Center(child: Text('Chưa load. Bấm "Refresh".'))
                : ListView(
                    children: _bags.map((b) => ListTile(
                          leading: const Icon(Icons.archive),
                          title: Text(b),
                        )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
