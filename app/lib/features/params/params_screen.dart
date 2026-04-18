import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

/// Tune các param Nav2 thường cần.
/// Map tới service /<node>/set_parameters với format rcl_interfaces/Parameter.
class ParamsScreen extends ConsumerStatefulWidget {
  const ParamsScreen({super.key});

  @override
  ConsumerState<ParamsScreen> createState() => _ParamsScreenState();
}

class _ParamsScreenState extends ConsumerState<ParamsScreen> {
  final Map<String, double> _values = {
    'controller_server|FollowPath.max_vel_x': 0.5,
    'controller_server|FollowPath.max_vel_theta': 1.2,
    'global_costmap/global_costmap|inflation_layer.inflation_radius': 0.55,
    'local_costmap/local_costmap|inflation_layer.inflation_radius': 0.35,
    'planner_server|GridBased.tolerance': 0.25,
  };

  Future<void> _apply(String key, double value) async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final parts = key.split('|');
    final node = parts[0];
    final paramName = parts[1];
    final req = {
      'parameters': [
        {
          'name': paramName,
          'value': {'type': 3, 'double_value': value}, // 3 = PARAMETER_DOUBLE
        }
      ],
    };
    final res = await client.callService(
      name: RosServices.setParameters(node),
      type: RosTypes.setParamsSrv,
      request: req,
    );
    if (!mounted) return;
    final ok = (res?['results'] as List?)?.every((r) => r['successful'] == true) ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$paramName = $value — ${ok ? "OK" : "FAILED"}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in _values.entries)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key.split('|')[1],
                      style: Theme.of(context).textTheme.titleSmall),
                  Text('Node: ${entry.key.split('|')[0]}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Slider(
                    value: entry.value,
                    min: 0,
                    max: entry.key.contains('vel_theta') ? 3.0 : 2.0,
                    divisions: 40,
                    label: entry.value.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _values[entry.key] = v),
                    onChangeEnd: (v) => _apply(entry.key, v),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
