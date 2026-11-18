import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/config/firestore_emulator_configuration.dart';

void main() {
  test('通常起動ではエミュレータ設定を使用しない', () {
    expect(FirestoreEmulatorConfiguration.parse(enabled: false), isNull);
  });

  test('テスト専用プロジェクトとループバック接続先を使用する', () {
    final config = FirestoreEmulatorConfiguration.parse(
      enabled: true,
      fixedNow: '2026-11-15T12:00:00+09:00',
    )!;
    expect(config.projectId, 'demo-memora-read-regression');
    expect(config.host, '127.0.0.1');
    expect(config.firestorePort, 8080);
    expect(config.authPort, 9099);
    expect(config.clock.now().toUtc(), DateTime.utc(2026, 11, 15, 3));
    expect(config.clock.now().hour, 12);
  });

  test('固定時刻がないテスト構成を拒否する', () {
    expect(
      () => FirestoreEmulatorConfiguration.parse(enabled: true),
      throwsFormatException,
    );
  });

  test('日付だけの指定とタイムゾーンのない時刻を拒否する', () {
    for (final value in ['2026-11-15', '2026-11-15T12:00:00']) {
      expect(
        () => FirestoreEmulatorConfiguration.parse(
          enabled: true,
          fixedNow: value,
        ),
        throwsFormatException,
      );
    }
  });
}
