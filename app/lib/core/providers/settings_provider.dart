import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_boxes.dart';
import '../storage/models/app_settings.dart';

/// StateNotifier giữ AppSettings — tự ghi Hive mỗi khi đổi.
class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController() : super(HiveBoxes.readAppSettings());

  void update(AppSettings Function(AppSettings) mutator) {
    final next = mutator(state);
    state = next;
    HiveBoxes.writeAppSettings(next);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>(
        (_) => AppSettingsController());
