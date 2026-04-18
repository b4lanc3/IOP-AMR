import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ros/ros_client.dart';

/// Layout chính có navigation rail + content area.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

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
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex =
        _destinations.indexWhere((d) => location.startsWith(d.route)).clamp(0, 999);
    final client = ref.watch(activeRosClientProvider);
    final isWide = MediaQuery.of(context).size.width >= 720;

    final body = Row(
      children: [
        if (isWide)
          NavigationRail(
            selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
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
        Expanded(child: child),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(client?.profile.name ?? 'IOP-AMR'),
        actions: [
          _ConnectionStatusChip(),
          IconButton(
            tooltip: 'Chuyển robot',
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.go('/connection'),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].route),
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
  const _NavItem({required this.route, required this.icon, required this.label});
}

class _ConnectionStatusChip extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ConnectionStatusChip> createState() => _ConnectionStatusChipState();
}

class _ConnectionStatusChipState extends ConsumerState<_ConnectionStatusChip> {
  @override
  Widget build(BuildContext context) {
    final client = ref.watch(activeRosClientProvider);
    if (client == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Chip(label: Text('Chưa kết nối')),
      );
    }
    return StreamBuilder<RosConnectionStatus>(
      stream: client.status,
      initialData: client.currentStatus,
      builder: (context, snap) {
        final s = snap.data ?? RosConnectionStatus.disconnected;
        final (color, text) = switch (s) {
          RosConnectionStatus.connected   => (Colors.green,  'Kết nối'),
          RosConnectionStatus.connecting  => (Colors.orange, 'Đang kết nối…'),
          RosConnectionStatus.error       => (Colors.red,    'Lỗi'),
          RosConnectionStatus.disconnected=> (Colors.grey,   'Mất kết nối'),
        };
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Chip(
            avatar: CircleAvatar(backgroundColor: color, radius: 6),
            label: Text(text),
          ),
        );
      },
    );
  }
}
