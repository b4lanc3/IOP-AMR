import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';

/// Layout chính: NavigationRail (desktop) / Drawer + NavigationBar (mobile).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _estopEngaged = false;
  /// Tab NavigationBar (mobile); chỉ đổi khi route thuộc 5 shortcut hoặc user chọn tab.
  int _mobileBarIndex = 0;

  static const _destinations = <_NavItem>[
    _NavItem(route: '/dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(route: '/teleop', icon: Icons.gamepad_outlined, selectedIcon: Icons.sports_esports, label: 'Teleop'),
    _NavItem(route: '/camera', icon: Icons.videocam_outlined, selectedIcon: Icons.videocam, label: 'Camera'),
    _NavItem(route: '/lidar', icon: Icons.radar_outlined, selectedIcon: Icons.radar, label: 'LiDAR'),
    _NavItem(route: '/map', icon: Icons.map_outlined, selectedIcon: Icons.map, label: 'Map'),
    _NavItem(route: '/mapping', icon: Icons.layers_outlined, selectedIcon: Icons.layers, label: 'Mapping'),
    _NavItem(route: '/waypoints', icon: Icons.place_outlined, selectedIcon: Icons.place, label: 'Waypoints'),
    _NavItem(route: '/monitoring', icon: Icons.monitor_heart_outlined, selectedIcon: Icons.monitor_heart, label: 'Monitor'),
    _NavItem(route: '/params', icon: Icons.tune, selectedIcon: Icons.tune, label: 'Params'),
    _NavItem(route: '/logs', icon: Icons.history, selectedIcon: Icons.history_edu, label: 'Logs'),
    _NavItem(route: '/fleet', icon: Icons.hub_outlined, selectedIcon: Icons.hub, label: 'Fleet'),
    _NavItem(route: '/settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
  ];

  /// 5 mục hay dùng nhất trên thanh dưới mobile.
  static const _mobileBarRoutes = [
    '/dashboard',
    '/teleop',
    '/map',
    '/monitoring',
    '/settings',
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

  int _indexForRoute(String location) {
    final i = _destinations.indexWhere((d) => location.startsWith(d.route));
    return i == -1 ? 0 : i;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).uri.path;
    final i = _mobileBarRoutes.indexWhere((r) => loc.startsWith(r));
    if (i >= 0 && i != _mobileBarIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mobileBarIndex = i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexForRoute(location);
    final client = ref.watch(activeRosClientProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final scheme = Theme.of(context).colorScheme;
    final safeIndex = selectedIndex.clamp(0, _destinations.length - 1);

    final body = Row(
      children: [
        if (isWide)
          NavigationRail(
            extended: MediaQuery.sizeOf(context).width >= 1200,
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => context.go(_destinations[i].route),
            labelType: NavigationRailLabelType.all,
            minWidth: 72,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
        if (isWide) const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: ColoredBox(
            color: scheme.surfaceContainerLowest,
            child: widget.child,
          ),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: scheme.primaryContainer,
                            child: Icon(Icons.smart_toy, color: scheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('IOP-AMR',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        )),
                                Text(
                                  'Điều khiển & giám sát',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    for (var i = 0; i < _destinations.length; i++)
                      ListTile(
                        leading: Icon(
                          location.startsWith(_destinations[i].route)
                              ? _destinations[i].selectedIcon
                              : _destinations[i].icon,
                        ),
                        title: Text(_destinations[i].label),
                        selected: location.startsWith(_destinations[i].route),
                        onTap: () {
                          context.go(_destinations[i].route);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
            ),
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                client?.profile.name ?? 'IOP-AMR Control',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          const _ConnectionStatusChip(),
          IconButton(
            tooltip: 'Đổi robot',
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () => context.go('/connection'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      floatingActionButton: client == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggleEstop,
              elevation: 4,
              backgroundColor: _estopEngaged ? scheme.error : scheme.errorContainer,
              foregroundColor: _estopEngaged ? scheme.onError : scheme.onErrorContainer,
              icon: Icon(
                _estopEngaged ? Icons.emergency_rounded : Icons.warning_amber_rounded,
              ),
              label: Text(_estopEngaged ? 'E-STOP ON' : 'E-STOP'),
            ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _mobileBarIndex.clamp(0, _mobileBarRoutes.length - 1),
              onDestinationSelected: (i) {
                setState(() => _mobileBarIndex = i);
                context.go(_mobileBarRoutes[i]);
              },
              destinations: [
                for (final route in _mobileBarRoutes)
                  NavigationDestination(
                    icon: Icon(_destinations
                        .firstWhere((d) => d.route == route)
                        .icon),
                    selectedIcon: Icon(_destinations
                        .firstWhere((d) => d.route == route)
                        .selectedIcon),
                    label: _destinations.firstWhere((d) => d.route == route).label,
                  ),
              ],
            ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _ConnectionStatusChip extends ConsumerWidget {
  const _ConnectionStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(activeRosClientProvider);
    final scheme = Theme.of(context).colorScheme;
    if (client == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Chip(
          avatar: Icon(Icons.link_off, size: 18, color: scheme.outline),
          label: const Text('Chưa kết nối'),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    final statusAsync = ref.watch(activeRosStatusProvider);
    final s = statusAsync.value ?? client.currentStatus;
    final (icon, color, text) = switch (s) {
      RosConnectionStatus.connected => (Icons.cloud_done_rounded, scheme.primary, 'Online'),
      RosConnectionStatus.connecting => (Icons.cloud_sync_rounded, scheme.tertiary, 'Đang nối…'),
      RosConnectionStatus.error => (Icons.error_outline_rounded, scheme.error, 'Lỗi'),
      RosConnectionStatus.disconnected => (Icons.cloud_off_rounded, scheme.outline, 'Offline'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(text),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
