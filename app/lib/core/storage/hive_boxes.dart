import 'package:hive_flutter/hive_flutter.dart';

import 'models/app_settings.dart';
import 'models/gamepad_profile.dart';
import 'models/robot_profile.dart';
import 'models/waypoint.dart';

/// Trung tâm quản lý các Hive box.
class HiveBoxes {
  static const robotsBoxName = 'robots';
  static const missionsBoxName = 'missions';
  static const settingsBoxName = 'settings';
  static const gamepadProfilesBoxName = 'gamepad_profiles';
  static const appSettingsKey = 'app_settings';

  /// Profile robot mặc định (chỉ thêm khi chưa có robot nào — lần đầu cài app).
  static const presetDdeAmrId = 'preset-dde-amr';

  static late Box<RobotProfile> robots;
  static late Box<Mission> missions;
  static late Box<dynamic> settings;
  static late Box<GamepadProfile> gamepadProfiles;

  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(RobotProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(WaypointAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MissionAdapter());
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(GamepadProfileAdapter());
    }
  }

  static Future<void> openAll() async {
    robots = await Hive.openBox<RobotProfile>(robotsBoxName);
    missions = await Hive.openBox<Mission>(missionsBoxName);
    settings = await Hive.openBox<dynamic>(settingsBoxName);
    gamepadProfiles =
        await Hive.openBox<GamepadProfile>(gamepadProfilesBoxName);
    _ensureDefaults();
  }

  static void _ensureDefaults() {
    if (!settings.containsKey(appSettingsKey)) {
      settings.put(appSettingsKey, AppSettings());
    }
    if (gamepadProfiles.isEmpty) {
      final defaultId = 'flydigi-direwolf-default';
      gamepadProfiles.put(
        defaultId,
        GamepadProfile(id: defaultId, name: 'Flydigi Direwolf (default)'),
      );
      final current = settings.get(appSettingsKey) as AppSettings;
      settings.put(
        appSettingsKey,
        current.copyWith(activeGamepadProfileId: defaultId),
      );
    }
    _ensurePresetRobotProfile();
  }

  /// Robot mặc định DDE-AMR (Tailscale). Chỉ seed khi danh sách robot đang trống.
  static void _ensurePresetRobotProfile() {
    if (robots.isNotEmpty) return;
    robots.put(
      presetDdeAmrId,
      RobotProfile(
        id: presetDdeAmrId,
        name: 'DDE-AMR',
        host: '100.117.81.58',
        port: 9090,
        namespace: '',
        videoPort: 8080,
      ),
    );
  }

  static AppSettings readAppSettings() =>
      (settings.get(appSettingsKey) as AppSettings?) ?? AppSettings();

  static Future<void> writeAppSettings(AppSettings s) =>
      settings.put(appSettingsKey, s);

  static Future<void> closeAll() async {
    await robots.close();
    await missions.close();
    await settings.close();
    await gamepadProfiles.close();
  }
}
