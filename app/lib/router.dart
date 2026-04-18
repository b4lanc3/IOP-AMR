import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'features/teleop/teleop_screen.dart';
import 'features/waypoints/waypoints_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connection',
    routes: [
      GoRoute(
        path: '/connection',
        builder: (context, state) => const ConnectionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/teleop', builder: (c, s) => const TeleopScreen()),
          GoRoute(path: '/camera', builder: (c, s) => const CameraScreen()),
          GoRoute(path: '/lidar', builder: (c, s) => const LidarScreen()),
          GoRoute(path: '/map', builder: (c, s) => const MapScreen()),
          GoRoute(path: '/mapping', builder: (c, s) => const MappingScreen()),
          GoRoute(path: '/waypoints', builder: (c, s) => const WaypointsScreen()),
          GoRoute(path: '/monitoring', builder: (c, s) => const MonitoringScreen()),
          GoRoute(path: '/params', builder: (c, s) => const ParamsScreen()),
          GoRoute(path: '/logs', builder: (c, s) => const LogsScreen()),
          GoRoute(path: '/fleet', builder: (c, s) => const FleetScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
