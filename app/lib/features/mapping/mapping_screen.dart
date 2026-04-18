import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

class MappingScreen extends ConsumerStatefulWidget {
  const MappingScreen({super.key});

  @override
  ConsumerState<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends ConsumerState<MappingScreen> {
  late final TextEditingController _nameCtrl;
  bool _running = false;
  bool _busy = false;
  String? _last;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: 'map_${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _slam(String action) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    setState(() => _busy = true);
    try {
      final res = await client.callService(
        name: RosServices.slamControl,
        type: RosTypes.slamControlSrv,
        request: {'action': action, 'map_name': _nameCtrl.text.trim()},
      );
      if (!mounted) return;
      setState(() {
        _last = 'SLAM $action: ${res?['message'] ?? "sent"}';
        if (action == 'start') _running = true;
        if (action == 'stop') _running = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _last = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    setState(() => _busy = true);
    try {
      await client.callService(
        name: RosServices.saveMap,
        type: RosTypes.saveMapSrv,
        request: {'name': _nameCtrl.text.trim()},
      );
      if (!mounted) return;
      setState(() => _last = 'Đã yêu cầu lưu map "${_nameCtrl.text}"');
    } catch (e) {
      if (!mounted) return;
      setState(() => _last = 'Save lỗi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined),
              const SizedBox(width: 8),
              Text('SLAM Mapping',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (_running)
                const Chip(
                  avatar:
                      CircleAvatar(backgroundColor: Colors.green, radius: 6),
                  label: Text('Đang mapping'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Map name'),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: (_running || _busy) ? null : () => _slam('start'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
              FilledButton.tonalIcon(
                onPressed: (!_running || _busy) ? null : () => _slam('stop'),
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save map'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _slam('reset'),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Xem real-time ở Map'),
              ),
            ],
          ),
          if (_last != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_last!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quy trình quét bản đồ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('1. Bấm Start để chạy slam_toolbox.\n'
                      '2. Sang tab Map hoặc Teleop, lái robot đi chậm quanh khu vực.\n'
                      '3. Khi thấy map đủ chi tiết, quay lại đây và bấm Save map.\n'
                      '4. Sau khi save, có thể Stop để tắt SLAM → chuyển sang chế độ navigation.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
