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
import '../../l10n/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.connectionScanDone(found.length))),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _addOrEdit([RobotProfile? original]) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<RobotProfile>(
      context: context,
      builder: (_) => _RobotDialog(l10n: l10n, original: original),
    );
    if (result != null) {
      await HiveBoxes.robots.put(result.id, result);
    }
  }

  Future<void> _delete(RobotProfile p) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.connectionDeleteRobotTitle(p.name)),
        content: Text(l10n.connectionDeleteRobotBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete)),
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.connectionFailedRetry(profile.name)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final robotsAsync = ref.watch(robotProfilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connectionTitle),
        actions: [
          IconButton(
            tooltip: l10n.connectionScanMdns,
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
            tooltip: l10n.connectionSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: robotsAsync.when(
        data: (robots) {
          if (robots.isEmpty) return _EmptyState(l10n: l10n);
          final sorted = robots.toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: HeroBanner(
                    title: l10n.connectionHeroTitle,
                    subtitle: l10n.connectionHeroSubtitle,
                    icon: Icons.hub_rounded,
                    chips: [
                      _HeroChip(
                        icon: Icons.smart_toy_rounded,
                        label: l10n.connectionRobotsSaved(sorted.length),
                        color: AppTheme.brandAccent,
                      ),
                      _HeroChip(
                        icon: Icons.cable_rounded,
                        label: l10n.connectionRosbridgeChip,
                        color: AppTheme.brandPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _NetworkHintCard(l10n: l10n)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverList.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final r = sorted[i];
                    return _RobotCard(
                      l10n: l10n,
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
        error: (e, __) =>
            Center(child: Text(l10n.connectionError(e.toString()))),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: Text(l10n.connectionAddIp),
      ),
    );
  }
}

class _RobotCard extends StatefulWidget {
  const _RobotCard({
    required this.l10n,
    required this.profile,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
  });

  final AppLocalizations l10n;
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
      setState(
          () => _pingResult = widget.l10n.connectionPingUnreachable);
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
                        label: widget.l10n.connectionNamespacePill(
                          p.namespace.isEmpty ? '—' : p.namespace,
                        ),
                      ),
                      _MiniPill(
                        icon: Icons.videocam_outlined,
                        label: widget.l10n.connectionVideoPill(p.videoPort),
                      ),
                      if (_pingResult != null)
                        _MiniPill(
                          icon: Icons.network_ping,
                          label: widget.l10n.connectionPingPill(_pingResult!),
                          color: _pingResult ==
                                  widget.l10n.connectionPingUnreachable
                              ? scheme.error
                              : AppTheme.brandSuccess,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: widget.l10n.connectionPingTooltip,
              onPressed: _pinging ? null : _ping,
              icon: _pinging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_ping),
            ),
            IconButton(
              tooltip: widget.l10n.connectionEditTooltip,
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: widget.l10n.connectionDeleteTooltip,
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: widget.onConnect,
              icon: const Icon(Icons.link_rounded),
              label: Text(widget.l10n.connectionConnect),
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
  const _NetworkHintCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          leading: Icon(Icons.help_outline_rounded, color: scheme.primary),
          title: Text(l10n.connectionNetworkHelpTitle),
          subtitle: Text(l10n.connectionNetworkHelpSubtitle),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            _HintBullet(
              title: l10n.connectionHintLanTitle,
              body: l10n.connectionHintLanBody,
            ),
            const SizedBox(height: 12),
            _HintBullet(
              title: l10n.connectionHintTailscaleTitle,
              body: l10n.connectionHintTailscaleBody,
            ),
            const SizedBox(height: 12),
            _HintBullet(
              title: l10n.connectionHintNotTailscaleTitle,
              body: l10n.connectionHintNotTailscaleBody,
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
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

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
                    l10n.connectionEmptyTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.connectionEmptyBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _TipRow(
                      icon: Icons.add_circle_outline,
                      text: l10n.connectionTipAddIp),
                  const SizedBox(height: 8),
                  _TipRow(icon: Icons.radar, text: l10n.connectionTipMdns),
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
  const _RobotDialog({required this.l10n, this.original});

  final AppLocalizations l10n;
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
    final l10n = widget.l10n;
    final isEdit = widget.original != null;
    return AlertDialog(
      title:
          Text(isEdit ? l10n.connectionDialogEditTitle : l10n.connectionDialogAddTitle),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l10n.connectionDisplayName),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.connectionNameRequired : null,
              ),
              TextFormField(
                controller: _host,
                decoration:
                    InputDecoration(labelText: l10n.connectionHost),
                validator: (v) =>
                    v == null || v.isEmpty ? l10n.connectionHostRequired : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _port,
                      decoration: InputDecoration(
                          labelText: l10n.connectionRosbridgePort),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _videoPort,
                      decoration: InputDecoration(
                          labelText: l10n.connectionVideoPort),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _ns,
                decoration: InputDecoration(
                  labelText: l10n.connectionNamespaceOptional,
                  hintText: l10n.connectionNamespaceHint,
                ),
              ),
              TextFormField(
                controller: _token,
                decoration: InputDecoration(
                  labelText: l10n.connectionAuthTokenOptional,
                ),
                obscureText: true,
              ),
              SwitchListTile(
                value: _useSsl,
                onChanged: (v) => setState(() => _useSsl = v),
                title: Text(l10n.connectionUseWss),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel)),
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
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
