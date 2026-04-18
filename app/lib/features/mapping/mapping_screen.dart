import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class MappingScreen extends ConsumerStatefulWidget {
  const MappingScreen({super.key});

  @override
  ConsumerState<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends ConsumerState<MappingScreen> {
  bool _running = false;
  String _mapName = 'map_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

  Future<void> _slam(String action) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final res = await client.callService(
      name: RosServices.slamControl,
      type: RosTypes.slamControlSrv,
      request: {'action': action, 'map_name': _mapName},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('SLAM $action: ${res?['message'] ?? "sent"}')),
    );
    if (action == 'start') setState(() => _running = true);
    if (action == 'stop')  setState(() => _running = false);
  }

  Future<void> _save() async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    await client.callService(
      name: RosServices.saveMap,
      type: RosTypes.saveMapSrv,
      request: {'name': _mapName},
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã yêu cầu lưu map "$_mapName"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SLAM Mapping', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Map name'),
            controller: TextEditingController(text: _mapName),
            onChanged: (v) => _mapName = v,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _running ? null : () => _slam('start'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
              FilledButton.tonalIcon(
                onPressed: _running ? () => _slam('stop') : null,
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save map'),
              ),
              OutlinedButton.icon(
                onPressed: () => _slam('reset'),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _running
                    ? 'Đang quét. Sang tab Map để xem real-time, lái robot di chuyển quanh khu vực để SLAM Toolbox dựng map.'
                    : 'Mapping chưa chạy.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
