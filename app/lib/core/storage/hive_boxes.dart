import 'package:hive_flutter/hive_flutter.dart';

import 'models/robot_profile.dart';
import 'models/waypoint.dart';

/// Trung tâm quản lý các Hive box.
class HiveBoxes {
  static const robotsBoxName = 'robots';
  static const missionsBoxName = 'missions';
  static const settingsBoxName = 'settings';
  static const gamepadProfilesBoxName = 'gamepad_profiles';

  static late Box<RobotProfile> robots;
  static late Box<Mission> missions;
  static late Box<dynamic> settings;
  static late Box<dynamic> gamepadProfiles;

  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(RobotProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(WaypointAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(MissionAdapter());
  }

  static Future<void> openAll() async {
    robots = await Hive.openBox<RobotProfile>(robotsBoxName);
    missions = await Hive.openBox<Mission>(missionsBoxName);
    settings = await Hive.openBox<dynamic>(settingsBoxName);
    gamepadProfiles = await Hive.openBox<dynamic>(gamepadProfilesBoxName);
  }

  static Future<void> closeAll() async {
    await robots.close();
    await missions.close();
    await settings.close();
    await gamepadProfiles.close();
  }
}
