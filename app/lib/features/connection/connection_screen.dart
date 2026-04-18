import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/discovery/mdns_scanner.dart';
import '../../core/providers/connection_provider.dart';
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
        final exists = HiveBoxes.robots.values
            .any((x) => x.host == r.host && x.port == r.port);
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

  Future<void> _addOrEdit([RobotProfile? original]) async {
    final result = await showDialog<RobotProfile>(
      context: context,
      builder: (_) => _RobotDialog(original: original),
    );
    if (result != null) {
      await HiveBoxes.robots.put(result.id, result);
    }
  }

  Future<void> _delete(RobotProfile p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá "${p.name}"?'),
        content: const Text('Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed == true) {
      await HiveBoxes.robots.delete(p.id);
    }
  }

  Future<void> _connect(RobotProfile profile) async {
    await ref.read(activeRobotControllerProvider).connectTo(profile);
    if (!mounted) return;
    final client = ref.read(activeRosClientProvider);
    if (client?.isConnected ?? false) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Không kết nối được ${profile.name} — đang tự retry…'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final robotsAsync = ref.watch(robotProfilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết nối robot'),
        actions: [
          IconButton(
            tooltip: 'Quét mDNS',
            icon: _scanning
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar),
            onPressed: _scanning ? null : _scan,
          ),
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: robotsAsync.when(
        data: (robots) {
          if (robots.isEmpty) return const _EmptyState();
          final sorted = robots.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = sorted[i];
              return _RobotCard(
                profile: r,
                onConnect: () => _connect(r),
                onEdit: () => _addOrEdit(r),
                onDelete: () => _delete(r),
              );
            },
          );
        },
        error: (e, __) => Center(child: Text('Lỗi: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm IP'),
      ),
    );
  }
}

class _RobotCard extends StatefulWidget {
  const _RobotCard({
    required this.profile,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  final RobotProfile profile;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_RobotCard> createState() => _RobotCardState();
}

class _RobotCardState extends State<_RobotCard> {
  String? _pingResult;
  bool _pinging = false;

  Future<void> _ping() async {
    setState(() {
      _pinging = true;
      _pingResult = null;
    });
    try {
      final sw = Stopwatch()..start();
      final socket = await Socket.connect(
        widget.profile.host,
        widget.profile.port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      sw.stop();
      setState(() => _pingResult = '${sw.elapsedMilliseconds} ms');
    } catch (e) {
      setState(() => _pingResult = 'không reach');
    } finally {
      if (mounted) setState(() => _pinging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.smart_toy_outlined)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(p.websocketUrl,
                      style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    'ns: ${p.namespace.isEmpty ? "—" : p.namespace}'
                    '   |   video:${p.videoPort}'
                    '${_pingResult != null ? "   |   ping: $_pingResult" : ""}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Test ping',
              onPressed: _pinging ? null : _ping,
              icon: _pinging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_ping),
            ),
            IconButton(
              tooltip: 'Sửa',
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Xoá',
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: widget.onConnect,
              icon: const Icon(Icons.link),
              label: const Text('Kết nối'),
            ),
          ],
        ),
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
          Text('Chưa có robot nào',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Nhấn "Thêm IP" hoặc quét mDNS ở thanh trên.'),
        ],
      ),
    );
  }
}

class _RobotDialog extends StatefulWidget {
  const _RobotDialog({this.original});
  final RobotProfile? original;

  @override
  State<_RobotDialog> createState() => _RobotDialogState();
}

class _RobotDialogState extends State<_RobotDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _videoPort;
  late final TextEditingController _ns;
  late final TextEditingController _token;
  late bool _useSsl;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    _name = TextEditingController(text: o?.name ?? 'AMR-1');
    _host = TextEditingController(text: o?.host ?? '192.168.1.100');
    _port = TextEditingController(text: (o?.port ?? 9090).toString());
    _videoPort =
        TextEditingController(text: (o?.videoPort ?? 8080).toString());
    _ns = TextEditingController(text: o?.namespace ?? '');
    _token = TextEditingController(text: o?.authToken ?? '');
    _useSsl = o?.useSsl ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    _port.dispose();
    _videoPort.dispose();
    _ns.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.original != null;
    return AlertDialog(
      title: Text(isEdit ? 'Sửa robot' : 'Thêm robot'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập tên' : null,
              ),
              TextFormField(
                controller: _host,
                decoration:
                    const InputDecoration(labelText: 'IP / hostname'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập host' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _port,
                      decoration: const InputDecoration(
                          labelText: 'rosbridge port'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _videoPort,
                      decoration: const InputDecoration(
                          labelText: 'video port'),
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
              TextFormField(
                controller: _token,
                decoration: const InputDecoration(
                  labelText: 'Auth token (optional)',
                ),
                obscureText: true,
              ),
              SwitchListTile(
                value: _useSsl,
                onChanged: (v) => setState(() => _useSsl = v),
                title: const Text('Dùng wss:// / https://'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ')),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            final id = widget.original?.id ?? const Uuid().v4();
            Navigator.pop(
              context,
              RobotProfile(
                id: id,
                name: _name.text.trim(),
                host: _host.text.trim(),
                port: int.tryParse(_port.text) ?? 9090,
                videoPort: int.tryParse(_videoPort.text) ?? 8080,
                namespace: _ns.text.trim(),
                useSsl: _useSsl,
                authToken:
                    _token.text.trim().isEmpty ? null : _token.text.trim(),
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
