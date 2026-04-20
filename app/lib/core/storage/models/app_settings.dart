import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_language.dart';

/// Đơn vị tốc độ hiển thị trên UI (ROS nội bộ luôn là m/s và rad/s).
enum DisplayUnits { metric, imperial }

/// Cài đặt cấp app — lưu trong Hive settings box.
class AppSettings {
  ThemeMode themeMode;
  DisplayUnits units;
  double defaultMaxLinear; // m/s
  double defaultMaxAngular; // rad/s
  int teleopPublishHz;
  bool autoReconnect;
  bool showGridOnLidar;
  String? activeGamepadProfileId;
  AppLanguage language;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.units = DisplayUnits.metric,
    this.defaultMaxLinear = 0.5,
    this.defaultMaxAngular = 1.2,
    this.teleopPublishHz = 15,
    this.autoReconnect = true,
    this.showGridOnLidar = true,
    this.activeGamepadProfileId,
    this.language = AppLanguage.vietnamese,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    DisplayUnits? units,
    double? defaultMaxLinear,
    double? defaultMaxAngular,
    int? teleopPublishHz,
    bool? autoReconnect,
    bool? showGridOnLidar,
    String? activeGamepadProfileId,
    AppLanguage? language,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        units: units ?? this.units,
        defaultMaxLinear: defaultMaxLinear ?? this.defaultMaxLinear,
        defaultMaxAngular: defaultMaxAngular ?? this.defaultMaxAngular,
        teleopPublishHz: teleopPublishHz ?? this.teleopPublishHz,
        autoReconnect: autoReconnect ?? this.autoReconnect,
        showGridOnLidar: showGridOnLidar ?? this.showGridOnLidar,
        activeGamepadProfileId:
            activeGamepadProfileId ?? this.activeGamepadProfileId,
        language: language ?? this.language,
      );
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 10;

  @override
  AppSettings read(BinaryReader r) {
    final n = r.readByte();
    final f = <int, dynamic>{};
    for (var i = 0; i < n; i++) {
      f[r.readByte()] = r.read();
    }
    final langIdx = (f[8] as int?) ?? 0;
    return AppSettings(
      themeMode: ThemeMode.values[(f[0] as int?) ?? 0],
      units: DisplayUnits.values[(f[1] as int?) ?? 0],
      defaultMaxLinear: ((f[2] as num?) ?? 0.5).toDouble(),
      defaultMaxAngular: ((f[3] as num?) ?? 1.2).toDouble(),
      teleopPublishHz: (f[4] as int?) ?? 15,
      autoReconnect: (f[5] as bool?) ?? true,
      showGridOnLidar: (f[6] as bool?) ?? true,
      activeGamepadProfileId: f[7] as String?,
      language: AppLanguage.values[
          langIdx.clamp(0, AppLanguage.values.length - 1)],
    );
  }

  @override
  void write(BinaryWriter w, AppSettings o) {
    w.writeByte(9);
    w.writeByte(0); w.write(o.themeMode.index);
    w.writeByte(1); w.write(o.units.index);
    w.writeByte(2); w.write(o.defaultMaxLinear);
    w.writeByte(3); w.write(o.defaultMaxAngular);
    w.writeByte(4); w.write(o.teleopPublishHz);
    w.writeByte(5); w.write(o.autoReconnect);
    w.writeByte(6); w.write(o.showGridOnLidar);
    w.writeByte(7); w.write(o.activeGamepadProfileId);
    w.writeByte(8); w.write(o.language.index);
  }
}
