import 'dart:io';

import 'package:amr_control/app.dart';
import 'package:amr_control/core/storage/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = Directory.systemTemp.createTempSync('amr_control_widget_test_');
    Hive.init(tmpDir.path);
    await HiveBoxes.registerAdapters();
    await HiveBoxes.openAll();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
  });

  testWidgets('AmrControlApp builds MaterialApp', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AmrControlApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
