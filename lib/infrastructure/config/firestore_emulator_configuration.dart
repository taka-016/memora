import 'package:flutter/foundation.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

class FirestoreEmulatorConfiguration {
  FirestoreEmulatorConfiguration._(this.clock);

  static const testProjectId = 'demo-memora-read-regression';
  final AppClock clock;
  String get projectId => testProjectId;
  String get host => '127.0.0.1';
  int get firestorePort => 8080;
  int get authPort => 9099;

  static FirestoreEmulatorConfiguration? fromEnvironment() => parse(
    enabled: const bool.fromEnvironment('MEMORA_FIRESTORE_READ_REGRESSION'),
    fixedNow: const String.fromEnvironment('MEMORA_TEST_NOW'),
    timeZone: const String.fromEnvironment(
      'MEMORA_TEST_TIME_ZONE',
      defaultValue: 'Asia/Tokyo',
    ),
  );

  static FirestoreEmulatorConfiguration? parse({
    required bool enabled,
    String fixedNow = '',
    String timeZone = 'Asia/Tokyo',
  }) {
    if (!enabled) return null;
    if (kReleaseMode) {
      throw StateError('読み取り回帰テストはreleaseビルドで実行できません');
    }
    final instant = DateTime.tryParse(fixedNow);
    if (instant == null ||
        !RegExp(r'T\d{2}:\d{2}:\d{2}.*(Z|[+-]\d{2}:\d{2})$')
            .hasMatch(fixedNow)) {
      throw const FormatException('テストの固定時刻にはタイムゾーン付き日時が必要です');
    }
    data.initializeTimeZones();
    final location = tz.timeZoneDatabase.locations[timeZone];
    if (location == null) {
      throw FormatException('未対応のテスト用タイムゾーンです: $timeZone');
    }
    return FirestoreEmulatorConfiguration._(
      FixedAppClock(tz.TZDateTime.from(instant, location)),
    );
  }
}
