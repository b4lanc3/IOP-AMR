import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/param_service.dart';
import '../../core/ros/ros_client.dart';
import '../../l10n/app_localizations.dart';

/// Tune các param Nav2 thường dùng. Hỗ trợ cả slider double và switch bool.
class ParamsScreen extends ConsumerStatefulWidget {
  const ParamsScreen({super.key});

  @override
  ConsumerState<ParamsScreen> createState() => _ParamsScreenState();
}

class _ParamDef {
  final String node;
  final String name;
  final RosParamType type;
  final double min;
  final double max;
  final int? divisions;
  final String? unit;
  _ParamDef.double({
    required this.node,
    required this.name,
    required double initial,
    required this.min,
    required this.max,
    this.divisions,
    this.unit,
  })  : type = RosParamType.double,
        _initial = initial;
  _ParamDef.boolean({
    required this.node,
    required this.name,
    required bool initial,
  })  : type = RosParamType.boolean,
        min = 0,
        max = 1,
        divisions = null,
        unit = null,
        _initial = initial;

  final dynamic _initial;
  String get id => '$node|$name';
}

String? _paramDescription(AppLocalizations l10n, _ParamDef d) {
  if (d.node == 'controller_server' && d.name == 'FollowPath.max_vel_x') {
    return l10n.paramsDescMaxVelX;
  }
  if (d.node == 'global_costmap/global_costmap' &&
      d.name == 'inflation_layer.inflation_radius') {
    return l10n.paramsDescInflationGlobal;
  }
  return null;
}

class _ParamsScreenState extends ConsumerState<ParamsScreen> {
  late final List<_ParamDef> _defs = [
    _ParamDef.double(
      node: 'controller_server',
      name: 'FollowPath.max_vel_x',
      initial: 0.5,
      min: 0,
      max: 2.0,
      divisions: 40,
      unit: 'm/s',
    ),
    _ParamDef.double(
      node: 'controller_server',
      name: 'FollowPath.max_vel_theta',
      initial: 1.2,
      min: 0,
      max: 3.5,
      divisions: 35,
      unit: 'rad/s',
    ),
    _ParamDef.double(
      node: 'controller_server',
      name: 'FollowPath.acc_lim_x',
      initial: 2.5,
      min: 0,
      max: 5,
      divisions: 50,
      unit: 'm/s²',
    ),
    _ParamDef.double(
      node: 'global_costmap/global_costmap',
      name: 'inflation_layer.inflation_radius',
      initial: 0.55,
      min: 0,
      max: 2.0,
      divisions: 40,
      unit: 'm',
    ),
    _ParamDef.double(
      node: 'local_costmap/local_costmap',
      name: 'inflation_layer.inflation_radius',
      initial: 0.35,
      min: 0,
      max: 2.0,
      divisions: 40,
      unit: 'm',
    ),
    _ParamDef.double(
      node: 'planner_server',
      name: 'GridBased.tolerance',
      initial: 0.25,
      min: 0,
      max: 1,
      divisions: 40,
      unit: 'm',
    ),
    _ParamDef.boolean(
      node: 'bt_navigator',
      name: 'use_sim_time',
      initial: false,
    ),
  ];

  late final Map<String, dynamic> _values = {
    for (final d in _defs) d.id: d._initial,
  };
  String? _lastStatus;
  bool _busy = false;

  Future<void> _apply(_ParamDef def) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final l10n = AppLocalizations.of(context);
    final value = switch (def.type) {
      RosParamType.double => RosParamValue.fromDouble(
          (_values[def.id] as num).toDouble()),
      RosParamType.boolean => RosParamValue.fromBool(_values[def.id] as bool),
      _ => null,
    };
    if (value == null) return;
    final svc = RosParamService(client, def.node);
    setState(() => _busy = true);
    try {
      final ok = await svc.setParam(def.name, value);
      if (!mounted) return;
      setState(() => _lastStatus = l10n.paramsSetStatus(
          def.name, _values[def.id].toString(), ok ? 'OK' : 'FAILED'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastStatus = l10n.paramsSetError(def.name, e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _readBack() async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final nodes = _defs.map((d) => d.node).toSet();
      for (final node in nodes) {
        final names =
            _defs.where((d) => d.node == node).map((d) => d.name).toList();
        final svc = RosParamService(client, node);
        final res = await svc.getParams(names);
        final values = (res?['values'] as List?) ?? const [];
        for (var i = 0; i < values.length && i < names.length; i++) {
          final v = values[i] as Map<String, dynamic>;
          final type = v['type'];
          final id = '$node|${names[i]}';
          if (type == RosParamType.double.code) {
            _values[id] = (v['double_value'] as num?)?.toDouble() ?? _values[id];
          } else if (type == RosParamType.boolean.code) {
            _values[id] = v['bool_value'] ?? _values[id];
          }
        }
      }
      if (!mounted) return;
      setState(() => _lastStatus = l10n.paramsReadBackOk);
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastStatus = l10n.paramsReadBackError(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grouped = <String, List<_ParamDef>>{};
    for (final d in _defs) {
      grouped.putIfAbsent(d.node, () => []).add(d);
    }
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(children: [
              Text(l10n.paramsNav2LiveTuning,
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _busy ? null : _readBack,
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(l10n.paramsReadCurrent),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              l10n.paramsSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                child: Text(l10n.paramsNodeLabel(entry.key),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ),
              Card(
                child: Column(
                  children: [
                    for (final d in entry.value) _paramTile(d),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (_lastStatus != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_lastStatus!,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    if (_busy)
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _paramTile(_ParamDef d) {
    final l10n = AppLocalizations.of(context);
    final desc = _paramDescription(l10n, d);
    final value = _values[d.id];
    if (d.type == RosParamType.boolean) {
      return SwitchListTile(
        title: Text(d.name),
        subtitle: desc == null ? null : Text(desc),
        value: value as bool,
        onChanged: (v) {
          setState(() => _values[d.id] = v);
          _apply(d);
        },
      );
    }
    final v = (value as num).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Text(
                '${v.toStringAsFixed(2)}${d.unit == null ? "" : " ${d.unit}"}',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
          if (desc != null)
            Text(desc, style: Theme.of(context).textTheme.bodySmall),
          Slider(
            value: v.clamp(d.min, d.max),
            min: d.min,
            max: d.max,
            divisions: d.divisions,
            label: v.toStringAsFixed(2),
            onChanged: (nv) => setState(() => _values[d.id] = nv),
            onChangeEnd: (_) => _apply(d),
          ),
        ],
      ),
    );
  }
}
