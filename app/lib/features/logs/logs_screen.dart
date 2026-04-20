import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';
import '../../l10n/app_localizations.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final _bagName = TextEditingController(
      text: 'bag_${DateTime.now().millisecondsSinceEpoch ~/ 1000}');
  final _topics = TextEditingController(
      text: '/scan,/odom,/tf,/tf_static,/camera/color/image_raw');

  List<String> _bags = [];
  bool _recording = false;
  bool _busy = false;
  DateTime? _startedAt;
  Timer? _tick;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(activeRosClientProvider)?.isConnected ?? false) {
        _call('list', silent: true);
      }
    });
  }

  @override
  void dispose() {
    _bagName.dispose();
    _topics.dispose();
    _tick?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt!));
    });
  }

  void _stopTimer() {
    _tick?.cancel();
    _tick = null;
    _startedAt = null;
  }

  Future<void> _call(String action, {bool silent = false}) async {
    final client = ref.read(activeRosClientProvider);
    final l10n = AppLocalizations.of(context);
    if (client == null) {
      _toast(l10n.logsNotConnected);
      return;
    }
    setState(() => _busy = true);
    try {
      final req = {
        'action': action,
        'bag_name': _bagName.text.trim(),
        'topics': _topics.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };
      final res = await client.callService(
        name: RosServices.bagControl,
        type: RosTypes.bagControlSrv,
        request: req,
      );
      if (!mounted) return;
      setState(() {
        if (action == 'start') {
          _recording = true;
          _startTimer();
        }
        if (action == 'stop') {
          _recording = false;
          _stopTimer();
        }
        final bags = (res?['bags'] as List?)?.cast<String>();
        if (bags != null) _bags = bags;
      });
      if (!silent) {
        _toast(l10n.logsBagAction(
            action, res?['message']?.toString() ?? 'sent'));
      }
    } catch (e) {
      if (mounted) _toast(l10n.logsErrorAction(action, e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 8),
              Text(l10n.logsTitle,
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (_recording)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text('REC ${_fmt(_elapsed)}',
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bagName,
            enabled: !_recording,
            decoration: InputDecoration(
                labelText: l10n.logsBagName,
                prefixIcon: const Icon(Icons.drive_file_rename_outline)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _topics,
            enabled: !_recording,
            decoration: InputDecoration(
              labelText: l10n.logsTopicsComma,
              prefixIcon: const Icon(Icons.topic_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: (_recording || _busy) ? null : () => _call('start'),
                icon: const Icon(Icons.fiber_manual_record),
                label: Text(l10n.logsStart),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
              ),
              FilledButton.tonalIcon(
                onPressed: (_recording && !_busy) ? () => _call('stop') : null,
                icon: const Icon(Icons.stop),
                label: Text(l10n.logsStop),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _call('list'),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.logsRefreshList),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(children: [
            Text(l10n.logsAvailableBags,
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(l10n.logsBagCount(_bags.length),
                style: Theme.of(context).textTheme.bodySmall),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: _bags.isEmpty
                ? Center(
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.archive_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 8),
                      Text(l10n.logsEmpty),
                    ],
                  ))
                : Card(
                    child: ListView.separated(
                      itemCount: _bags.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) => ListTile(
                        leading: const Icon(Icons.archive),
                        title: Text(_bags[i]),
                        trailing: const Icon(Icons.copy, size: 16),
                        onTap: () {
                          // Could add download/export later.
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
