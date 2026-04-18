import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ros/msg_types.dart';
import '../../core/ros/ros_client.dart';
import '../../core/ros/topics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/ui_kit.dart';

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
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final isExtended = width >= 1200;
    final scheme = Theme.of(context).colorScheme;
    final safeIndex = selectedIndex.clamp(0, _destinations.length - 1);

    final body = Row(
      children: [
        if (isWide) _buildRail(context, safeIndex, isExtended),
        if (isWide)
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
            ),
            child: widget.child,
          ),
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWide ? null : _buildDrawer(context, location),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _GlassAppBar(
          onMenu: isWide
              ? null
              : () => _scaffoldKey.currentState?.openDrawer(),
          client: client,
        ),
      ),
      body: body,
      floatingActionButton: client == null ? null : _buildEstopFab(scheme),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex:
                  _mobileBarIndex.clamp(0, _mobileBarRoutes.length - 1),
              onDestinationSelected: (i) {
                setState(() => _mobileBarIndex = i);
                context.go(_mobileBarRoutes[i]);
              },
              destinations: [
                for (final route in _mobileBarRoutes)
                  NavigationDestination(
                    icon: Icon(
                        _destinations.firstWhere((d) => d.route == route).icon),
                    selectedIcon: Icon(_destinations
                        .firstWhere((d) => d.route == route)
                        .selectedIcon),
                    label:
                        _destinations.firstWhere((d) => d.route == route).label,
                  ),
              ],
            ),
    );
  }

  Widget _buildEstopFab(ColorScheme scheme) {
    final engaged = _estopEngaged;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (engaged ? scheme.error : scheme.error)
                .withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.dangerGradient(engaged ? 1 : 0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: FloatingActionButton.extended(
          onPressed: _toggleEstop,
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
          icon: Icon(
            engaged ? Icons.emergency_rounded : Icons.warning_amber_rounded,
            color: Colors.white,
          ),
          label: Text(
            engaged ? 'E-STOP ON' : 'E-STOP',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context, int safeIndex, bool extended) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: extended ? 236 : 86,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(size: 40),
                if (extended) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'IOP-AMR',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Control suite',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: NavigationRail(
              extended: extended,
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => context.go(_destinations[i].route),
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              minWidth: 72,
              minExtendedWidth: 236,
              backgroundColor: Colors.transparent,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, String location) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  const BrandMark(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'IOP-AMR',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Điều khiển & giám sát',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
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
          ],
        ),
      ),
    );
  }
}

class _GlassAppBar extends ConsumerWidget {
  const _GlassAppBar({required this.onMenu, required this.client});
  final VoidCallback? onMenu;
  final RosClient? client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      leading: onMenu == null
          ? null
          : IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenu,
            ),
      titleSpacing: onMenu == null ? 18 : 4,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onMenu == null) const BrandMark(size: 34),
          if (onMenu == null) const SizedBox(width: 10),
          Flexible(
            child: ShaderMask(
              shaderCallback: (r) =>
                  AppTheme.brandGradient.createShader(Rect.fromLTWH(
                0,
                0,
                r.width,
                r.height,
              )),
              child: Text(
                client?.profile.name ?? 'IOP-AMR Control',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      actions: [
        const _ConnectionStatusChip(),
        Tooltip(
          message: 'Đổi robot',
          child: IconButton.filledTonal(
            onPressed: () => context.go('/connection'),
            icon: const Icon(Icons.swap_horiz_rounded),
            style: IconButton.styleFrom(
              backgroundColor:
                  scheme.surfaceContainerHigh.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
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

    late final Color color;
    late final String label;
    late final bool pulsing;

    if (client == null) {
      color = scheme.outline;
      label = 'Chưa kết nối';
      pulsing = false;
    } else {
      final statusAsync = ref.watch(activeRosStatusProvider);
      final s = statusAsync.value ?? client.currentStatus;
      switch (s) {
        case RosConnectionStatus.connected:
          color = AppTheme.brandSuccess;
          label = 'Online';
          pulsing = true;
        case RosConnectionStatus.connecting:
          color = AppTheme.brandWarning;
          label = 'Đang nối…';
          pulsing = true;
        case RosConnectionStatus.error:
          color = scheme.error;
          label = 'Lỗi';
          pulsing = false;
        case RosConnectionStatus.disconnected:
          color = scheme.outline;
          label = 'Offline';
          pulsing = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: color, pulsing: pulsing, size: 9),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
