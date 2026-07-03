import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _settingsGradlePath = 'android/settings.gradle.kts';
const _gradleWrapperPropertiesPath =
    'android/gradle/wrapper/gradle-wrapper.properties';
const _appBuildGradlePath = 'android/app/build.gradle.kts';

void main() {
  group('AndroidGradleConfig', () {
    test('share_plus 13系のAndroidビルド要件を満たしている', () {
      final settingsGradle = File(_settingsGradlePath).readAsStringSync();
      final gradleWrapperProperties = File(
        _gradleWrapperPropertiesPath,
      ).readAsStringSync();
      final appBuildGradle = File(_appBuildGradlePath).readAsStringSync();

      _expectVersionAtLeast(
        settingsGradle,
        RegExp(r'id\("com\.android\.application"\) version "([^"]+)"'),
        const _Version(8, 12, 1),
      );
      _expectVersionAtLeast(
        settingsGradle,
        RegExp(r'id\("org\.jetbrains\.kotlin\.android"\) version "([^"]+)"'),
        const _Version(2, 2, 0),
      );
      _expectVersionAtLeast(
        gradleWrapperProperties,
        RegExp(r'gradle-([0-9.]+)-all\.zip'),
        const _Version(8, 13, 0),
      );
      expect(appBuildGradle, contains('JavaVersion.VERSION_17'));
      expect(appBuildGradle, contains('jvmTarget = JavaVersion.VERSION_17'));
    });
  });
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
