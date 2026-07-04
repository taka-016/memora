import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _settingsGradlePath = 'android/settings.gradle.kts';
const _gradleWrapperPropertiesPath =
    'android/gradle/wrapper/gradle-wrapper.properties';
const _appBuildGradlePath = 'android/app/build.gradle.kts';
const _localToastPluginBuildGradlePath =
    'packages/memora_android_widget_toast/android/build.gradle.kts';
const _todoPath = 'docs/todo.md';

void main() {
  group('AndroidGradleConfig', () {
    test('Flutter 3.44.4以降のAndroidビルド要件を満たしている', () {
      final settingsGradle = File(_settingsGradlePath).readAsStringSync();
      final gradleWrapperProperties = File(
        _gradleWrapperPropertiesPath,
      ).readAsStringSync();
      final appBuildGradle = File(_appBuildGradlePath).readAsStringSync();

      _expectVersionAtLeast(
        settingsGradle,
        RegExp(r'id\("com\.android\.application"\) version "([^"]+)"'),
        const _Version(9, 0, 1),
      );
      _expectVersionAtLeast(
        gradleWrapperProperties,
        RegExp(r'gradle-([0-9.]+)-all\.zip'),
        const _Version(9, 1, 0),
      );
      expect(appBuildGradle, contains('JavaVersion.VERSION_17'));
      expect(settingsGradle, contains('id("com.android.built-in-kotlin")'));
    });

    test('アプリ本体とローカルプラグインはbuilt-in Kotlinへ移行している', () {
      final settingsGradle = File(_settingsGradlePath).readAsStringSync();
      final gradleWrapperProperties = File(
        _gradleWrapperPropertiesPath,
      ).readAsStringSync();
      final appBuildGradle = File(_appBuildGradlePath).readAsStringSync();
      final localToastPluginBuildGradle = File(
        _localToastPluginBuildGradlePath,
      ).readAsStringSync();

      _expectVersionAtLeast(
        settingsGradle,
        RegExp(r'id\("com\.android\.application"\) version "([^"]+)"'),
        const _Version(9, 0, 1),
      );
      _expectVersionAtLeast(
        gradleWrapperProperties,
        RegExp(r'gradle-([0-9.]+)-all\.zip'),
        const _Version(9, 1, 0),
      );
      expect(
        settingsGradle,
        isNot(contains('id("org.jetbrains.kotlin.android")')),
      );
      expect(
        settingsGradle,
        contains('id("com.android.built-in-kotlin")'),
      );
      _expectBuiltInKotlinAppModule(appBuildGradle);
      _expectBuiltInKotlinCompatiblePluginModule(localToastPluginBuildGradle);
    });

    test('外部プラグインのbuilt-in Kotlin対応は将来更新todoとして残している', () {
      final todo = File(_todoPath).readAsStringSync();

      expect(
        todo,
        contains(
          'KGP未対応の外部プラグイン（home_widget、workmanager_android）が'
          'built-in Kotlin対応版に更新されたら対応する',
        ),
      );
      expect(todo, isNot(contains('memora_android_widget_toast、')));
    });
  });
}

void _expectBuiltInKotlinAppModule(String source) {
  expect(source, contains('id("com.android.built-in-kotlin")'));
  expect(source, isNot(contains('id("kotlin-android")')));
  expect(source, isNot(contains('id("org.jetbrains.kotlin.android")')));
  expect(source, isNot(contains('kotlinOptions')));
  expect(
    source,
    contains('jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17'),
  );
}

void _expectBuiltInKotlinCompatiblePluginModule(String source) {
  expect(source, isNot(contains('id("org.jetbrains.kotlin.android")')));
  expect(source, isNot(contains('kotlinOptions')));
  expect(source, contains('if (agpMajor < 9)'));
  expect(source, contains('apply(plugin = "org.jetbrains.kotlin.android")'));
  expect(
    source,
    contains('jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17'),
  );
}

void _expectVersionAtLeast(
  String source,
  RegExp pattern,
  _Version requiredVersion,
) {
  final match = pattern.firstMatch(source);
  expect(match, isNotNull);

  final actualVersion = _Version.parse(match!.group(1)!);
  expect(
    actualVersion.compareTo(requiredVersion),
    greaterThanOrEqualTo(0),
    reason: '$actualVersion は $requiredVersion 以上である必要があります',
  );
}

class _Version implements Comparable<_Version> {
  const _Version(this.major, this.minor, this.patch);

  factory _Version.parse(String value) {
    final parts = value.split('.').map(int.parse).toList();
    return _Version(parts[0], parts[1], parts.length > 2 ? parts[2] : 0);
  }

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(_Version other) {
    final majorComparison = major.compareTo(other.major);
    if (majorComparison != 0) {
      return majorComparison;
    }

    final minorComparison = minor.compareTo(other.minor);
    if (minorComparison != 0) {
      return minorComparison;
    }

    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}
