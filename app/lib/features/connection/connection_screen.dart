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
import '../../core/theme/app_theme.dart';
import '../../core/theme/ui_kit.dart';

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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: HeroBanner(
                    title: 'Fleet & kết nối',
                    subtitle:
                        'Chọn robot để làm việc, hoặc thêm IP thủ công / quét mDNS. '
                        'Sau khi nối rosbridge, app sẽ nhớ profile trên máy này.',
                    icon: Icons.hub_rounded,
                    chips: [
                      _HeroChip(
                        icon: Icons.smart_toy_rounded,
                        label: '${sorted.length} robot đã lưu',
                        color: AppTheme.brandAccent,
                      ),
                      const _HeroChip(
                        icon: Icons.cable_rounded,
                        label: 'rosbridge 9090 · video 8080',
                        color: AppTheme.brandPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _NetworkHintCard()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = sorted[i];
                    return _RobotCard(
                      profile: r,
                      onConnect: () => _connect(r),
                      onEdit: () => _addOrEdit(r),
                      onDelete: () => _delete(r),
                    );
                  },
                ),
              ),
            ],
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
    final scheme = Theme.of(context).colorScheme;
    final isTailscale = p.host.startsWith('100.');
    final netColor =
        isTailscale ? AppTheme.brandAccent : AppTheme.brandSuccess;
    final netLabel = isTailscale ? 'Tailscale' : 'LAN';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            const GradientIconBadge(
              icon: Icons.smart_toy_rounded,
              size: 44,
              radius: 14,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniBadge(label: netLabel, color: netColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.websocketUrl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _MiniPill(
                        icon: Icons.folder_outlined,
                        label: 'ns ${p.namespace.isEmpty ? "—" : p.namespace}',
                      ),
                      _MiniPill(
                        icon: Icons.videocam_outlined,
                        label: 'video ${p.videoPort}',
                      ),
                      if (_pingResult != null)
                        _MiniPill(
                          icon: Icons.network_ping,
                          label: 'ping $_pingResult',
                          color: _pingResult == 'không reach'
                              ? scheme.error
                              : AppTheme.brandSuccess,
                        ),
                    ],
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
              icon: const Icon(Icons.link_rounded),
              label: const Text('Kết nối'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Gợi ý chọn IP (LAN vs Tailscale) — không thay thế cấu hình firewall/router.
class _NetworkHintCard extends StatelessWidget {
  const _NetworkHintCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          leading: Icon(Icons.help_outline_rounded, color: scheme.primary),
          title: const Text('Mạng & robot: LAN, Tailscale, máy khác'),
          subtitle: const Text('Khi nào dùng IP LAN, khi nào dùng 100.x…'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: const [
            _HintBullet(
              title: 'Cùng Wi‑Fi / LAN (thường không cần Internet)',
              body:
                  'PC và Jetson cùng switch/Wi‑Fi: dùng IP mạng nội bộ của robot (vd. 192.168.x.x). '
                  'Đảm bảo rosbridge lắng nghe 0.0.0.0:9090 trên Jetson. '
                  'Cách này không phụ thuộc Tailscale.',
            ),
            SizedBox(height: 12),
            _HintBullet(
              title: 'Tailscale (IP 100.x.x.x — ví dụ DDE-AMR đặt sẵn)',
              body:
                  'Hai máy cùng tailnet: kết nối qua IP Tailscale được gán cho Jetson. '
                  'Phù hợp khi laptop và robot khác subnet hoặc ở xa. '
                  'Nếu bạn muốn làm việc “offline” nhưng vẫn cùng phòng: ưu tiên IP LAN thay vì 100.x. '
                  'Khi cả hai chỉ có Tailscale và mất Internet công cộng, kết nối phụ thuộc chế độ direct/relay của Tailscale.',
            ),
            SizedBox(height: 12),
            _HintBullet(
              title: 'Không cùng Tailscale',
              body:
                  'Gắn máy vào cùng tailnet, hoặc dùng VPN khác (WireGuard, ZeroTier…), '
                  'hoặc mở cổng rosbridge qua router (NAT + bảo mật). '
                  'Trong app: thêm profile mới với IP/port tương ứng.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HintBullet extends StatelessWidget {
  const _HintBullet({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.router_rounded,
                        size: 44, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chưa có robot',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thêm địa chỉ IP Jetson (rosbridge thường là cổng 9090) '
                    'hoặc quét mDNS nếu robot quảng bá trên LAN.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  const _TipRow(icon: Icons.add_circle_outline, text: 'Nút Thêm IP — nhập host, port, namespace'),
                  const SizedBox(height: 8),
                  const _TipRow(icon: Icons.radar, text: 'Quét mDNS — tìm robot trên mạng cục bộ'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
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
