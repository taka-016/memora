import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _buildGradlePath = 'android/app/build.gradle.kts';

void main() {
  group('Androidアプリバリアント', () {
    late String buildGradle;

    setUpAll(() {
      buildGradle = File(_buildGradlePath).readAsStringSync();
    });

    test('オンライン版は既存IDを維持しオフライン版は別IDを使用する', () {
      expect(buildGradle, contains('flavorDimensions += "appMode"'));
      expect(buildGradle, contains('create("online")'));
      expect(buildGradle, contains('create("offline")'));
      expect(buildGradle, contains('applicationId = "com.example.memora"'));
      expect(buildGradle, contains('applicationIdSuffix = ".offline"'));
    });

    test('各バリアントのネイティブモードを固定する', () {
      expect(
        buildGradle,
        contains(
          r'buildConfigField("String", "RESOLVED_APP_MODE", "\"online\"")',
        ),
      );
      expect(
        buildGradle,
        contains(
          r'buildConfigField("String", "RESOLVED_APP_MODE", "\"offline\"")',
        ),
      );
    });

    test('Dartで解決したモードと一致するバリアントだけを有効にする', () {
      expect(buildGradle, contains('androidComponents'));
      expect(buildGradle, contains('beforeVariants'));
      expect(buildGradle, contains('resolvedAppMode'));
      expect(buildGradle, contains('variantBuilder.enable ='));
    });

    test('モード未指定時はオンラインを使用しautoを受け付けない', () {
      expect(buildGradle, contains('?: "online"'));
      expect(buildGradle, isNot(contains('"auto", "online"')));
      expect(buildGradle, contains('MEMORA_APP_MODEにはonline、offlineのいずれか'));
    });

    test('Firebase設定はオンライン版だけへ適用する', () {
      expect(
        buildGradle,
        contains('id("com.google.gms.google-services") apply false'),
      );
      expect(buildGradle, contains('if (resolvedAppMode == "online")'));
      expect(
        buildGradle,
        contains('apply(plugin = "com.google.gms.google-services")'),
      );
    });
  });
}
