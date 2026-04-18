import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

/// Layout chính có navigation rail + content area.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _estopEngaged = false;

  static const _destinations = <_NavItem>[
    _NavItem(route: '/dashboard',  icon: Icons.dashboard_outlined,   label: 'Dashboard'),
    _NavItem(route: '/teleop',     icon: Icons.gamepad_outlined,     label: 'Teleop'),
    _NavItem(route: '/camera',     icon: Icons.videocam_outlined,    label: 'Camera'),
    _NavItem(route: '/lidar',      icon: Icons.radar_outlined,       label: 'LiDAR'),
    _NavItem(route: '/map',        icon: Icons.map_outlined,         label: 'Map'),
    _NavItem(route: '/mapping',    icon: Icons.layers_outlined,      label: 'Mapping'),
    _NavItem(route: '/waypoints',  icon: Icons.place_outlined,       label: 'Waypoints'),
    _NavItem(route: '/monitoring', icon: Icons.monitor_heart_outlined, label: 'Monitor'),
    _NavItem(route: '/params',     icon: Icons.tune,                 label: 'Params'),
    _NavItem(route: '/logs',       icon: Icons.history,              label: 'Logs'),
    _NavItem(route: '/fleet',      icon: Icons.hub_outlined,         label: 'Fleet'),
    _NavItem(route: '/settings',   icon: Icons.settings_outlined,    label: 'Settings'),
  ];

  Future<void> _toggleEstop() async {
    final client = ref.read(activeRosClientProvider);
    if (client == null) return;
    final next = !_estopEngaged;
    setState(() => _estopEngaged = next);
    client.publish(
      topic: RosTopics.cmdVel,
      type: RosTypes.twist,
      msg: const Twist.zero().toJson(),
    );
    try {
      await client.callService(
        name: RosServices.estop,
        type: RosTypes.estopSrv,
        request: {'engage': next},
        timeout: const Duration(seconds: 3),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('E-stop service lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _destinations
        .indexWhere((d) => location.startsWith(d.route))
        .clamp(0, 999);
    final client = ref.watch(activeRosClientProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;
    final safeIndex = selectedIndex == -1 ? 0 : selectedIndex;

    final body = Row(
      children: [
        if (isWide)
          NavigationRail(
            selectedIndex: safeIndex >= _destinations.length ? 0 : safeIndex,
            onDestinationSelected: (i) => context.go(_destinations[i].route),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
        if (isWide) const VerticalDivider(width: 1),
        Expanded(child: widget.child),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy_outlined),
            const SizedBox(width: 8),
            Text(client?.profile.name ?? 'IOP-AMR'),
          ],
        ),
        actions: [
          const _ConnectionStatusChip(),
          IconButton(
            tooltip: 'Chuyển robot',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.go('/connection'),
          ),
        ],
      ),
      body: body,
      floatingActionButton: client == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggleEstop,
              backgroundColor:
                  _estopEngaged ? Colors.red : Colors.orange.shade700,
              foregroundColor: Colors.white,
              icon: Icon(_estopEngaged
                  ? Icons.emergency
                  : Icons.warning_amber_rounded),
              label: Text(_estopEngaged ? 'E-STOP ON' : 'E-STOP'),
            ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: safeIndex.clamp(0, 4),
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].route),
              destinations: [
                for (final d in _destinations.take(5))
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
            ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
  });
}

class _ConnectionStatusChip extends ConsumerWidget {
  const _ConnectionStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(activeRosClientProvider);
    if (client == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Chip(label: Text('Chưa kết nối')),
      );
    }
    final statusAsync = ref.watch(activeRosStatusProvider);
    final s = statusAsync.value ?? client.currentStatus;
    final (color, text) = switch (s) {
      RosConnectionStatus.connected => (Colors.green, 'Kết nối'),
      RosConnectionStatus.connecting => (Colors.orange, 'Đang kết nối…'),
      RosConnectionStatus.error => (Colors.red, 'Lỗi'),
      RosConnectionStatus.disconnected => (Colors.grey, 'Mất kết nối'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        avatar: CircleAvatar(backgroundColor: color, radius: 6),
        label: Text(text),
      ),
    );
  }
}
