import 'package:flutter/material.dart';

/// Ngôn ngữ giao diện — lưu index trong Hive (AppSettings).
enum AppLanguage {
  vietnamese,
  english,
}

extension AppLanguageX on AppLanguage {
  Locale get locale => switch (this) {
        AppLanguage.vietnamese => const Locale('vi'),
        AppLanguage.english => const Locale('en'),
      };

  String get code => switch (this) {
        AppLanguage.vietnamese => 'vi',
        AppLanguage.english => 'en',
      };

  static AppLanguage fromCode(String? code) {
    if (code == 'en') return AppLanguage.english;
    return AppLanguage.vietnamese;
  }
}
