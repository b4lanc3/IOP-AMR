import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation/app_page_transitions.dart';
import 'features/camera/camera_screen.dart';
import 'features/connection/connection_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/fleet/fleet_screen.dart';
import 'features/lidar/lidar_screen.dart';
import 'features/logs/logs_screen.dart';
import 'features/map/map_screen.dart';
import 'features/mapping/mapping_screen.dart';
import 'features/monitoring/monitoring_screen.dart';
import 'features/params/params_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/waypoints/waypoints_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connection',
    redirect: (context, state) {
      if (state.uri.path == '/teleop') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/connection',
        pageBuilder: (context, state) => appFullScreenPage(
          key: state.pageKey,
          child: const ConnectionScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (c, s) => appShellPage(
              key: s.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/camera',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const CameraScreen()),
          ),
          GoRoute(
            path: '/lidar',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const LidarScreen()),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const MapScreen()),
          ),
          GoRoute(
            path: '/mapping',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const MappingScreen()),
          ),
          GoRoute(
            path: '/waypoints',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const WaypointsScreen()),
          ),
          GoRoute(
            path: '/monitoring',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const MonitoringScreen()),
          ),
          GoRoute(
            path: '/params',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const ParamsScreen()),
          ),
          GoRoute(
            path: '/logs',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const LogsScreen()),
          ),
          GoRoute(
            path: '/fleet',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const FleetScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) =>
                appShellPage(key: s.pageKey, child: const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
