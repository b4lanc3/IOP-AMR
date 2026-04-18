import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/discovery/mdns_scanner.dart';
import '../../core/ros/ros_client.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/storage/models/robot_profile.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  bool _scanning = false;
  final _scanner = MdnsScanner();

  Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final found = await _scanner.scan();
      for (final r in found) {
        final exists = HiveBoxes.robots.values.any((x) => x.host == r.host && x.port == r.port);
        if (!exists) {
          final profile = RobotProfile(
            id: const Uuid().v4(),
            name: r.name.replaceAll('.local', ''),
            host: r.host,
            port: r.port,
          );
          await HiveBoxes.robots.put(profile.id, profile);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quét xong: ${found.length} robot')),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addManual() async {
    final result = await showDialog<RobotProfile>(
      context: context,
      builder: (_) => const _AddRobotDialog(),
    );
    if (result != null) {
      await HiveBoxes.robots.put(result.id, result);
      if (mounted) setState(() {});
    }
  }

  Future<void> _connect(RobotProfile profile) async {
    final previous = ref.read(activeRosClientProvider);
    if (previous != null) {
      await previous.dispose();
    }
    final client = RosClient(profile);
    ref.read(activeRosClientProvider.notifier).state = client;
    await client.connect();
    if (!mounted) return;
    if (client.isConnected) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không kết nối được robot')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final robots = HiveBoxes.robots.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối robot'),
        actions: [
          IconButton(
            tooltip: 'Quét mDNS',
            icon: _scanning
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar),
            onPressed: _scanning ? null : _scan,
          ),
        ],
      ),
      body: robots.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: robots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = robots[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.smart_toy_outlined, size: 32),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${r.websocketUrl}  |  ns: ${r.namespace.isEmpty ? "—" : r.namespace}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Xoá',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await HiveBoxes.robots.delete(r.id);
                            if (mounted) setState(() {});
                          },
                        ),
                        FilledButton.icon(
                          onPressed: () => _connect(r),
                          icon: const Icon(Icons.link),
                          label: const Text('Kết nối'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManual,
        icon: const Icon(Icons.add),
        label: const Text('Thêm IP'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64),
          const SizedBox(height: 16),
          Text('Chưa có robot nào', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Nhấn "Thêm IP" hoặc quét mDNS ở thanh trên.'),
        ],
      ),
    );
  }
}

class _AddRobotDialog extends StatefulWidget {
  const _AddRobotDialog();

  @override
  State<_AddRobotDialog> createState() => _AddRobotDialogState();
}

class _AddRobotDialogState extends State<_AddRobotDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'AMR-1');
  final _host = TextEditingController(text: '192.168.1.100');
  final _port = TextEditingController(text: '9090');
  final _videoPort = TextEditingController(text: '8080');
  final _ns = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _videoPort.dispose();
    _ns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm robot'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên' : null,
              ),
              TextFormField(
                controller: _host,
                decoration: const InputDecoration(labelText: 'IP / hostname'),
                validator: (v) => v == null || v.isEmpty ? 'Nhập host' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _port,
                      decoration: const InputDecoration(labelText: 'rosbridge port'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _videoPort,
                      decoration: const InputDecoration(labelText: 'video port'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _ns,
                decoration: const InputDecoration(
                  labelText: 'Namespace (optional)',
                  hintText: 'vd: /robot_1',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              RobotProfile(
                id: const Uuid().v4(),
                name: _name.text.trim(),
                host: _host.text.trim(),
                port: int.tryParse(_port.text) ?? 9090,
                videoPort: int.tryParse(_videoPort.text) ?? 8080,
                namespace: _ns.text.trim(),
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
