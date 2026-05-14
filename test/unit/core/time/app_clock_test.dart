import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/time/app_clock.dart';

void main() {
  group('FixedAppClock', () {
    test('固定したUTC時刻を返す', () async {
      final fixedNow = DateTime.utc(2026, 5, 14, 1, 2, 3);
      final clock = FixedAppClock(fixedNow);

      expect(await clock.nowUtc(), fixedNow);
    });

    test('固定時刻がローカル時刻で渡されてもUTCへ正規化する', () async {
      final localNow = DateTime(2026, 5, 14, 1, 2, 3);
      final clock = FixedAppClock(localNow);

      expect((await clock.nowUtc()).isUtc, isTrue);
    });
  });
}
