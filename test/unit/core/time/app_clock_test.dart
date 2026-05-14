import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/time/app_clock.dart';

void main() {
  group('NtpSynchronizedAppClock', () {
    test('NTP時刻との差分を使って現在時刻をUTCで返す', () async {
      var systemNow = DateTime.utc(2026, 5, 14, 10);
      final clock = NtpSynchronizedAppClock(
        systemNow: () => systemNow,
        fetchNtpTime: () async => DateTime.utc(2026, 5, 14, 10, 5),
      );

      await clock.sync();
      systemNow = DateTime.utc(2026, 5, 14, 10, 1);

      expect(clock.nowUtc(), DateTime.utc(2026, 5, 14, 10, 6));
      expect(clock.nowUtc().isUtc, isTrue);
    });

    test('固定時刻に差し替えられる', () {
      final fixed = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final clock = FixedAppClock(fixed);

      expect(clock.nowUtc(), fixed);
      expect(clock.nowLocal(), fixed.toLocal());
    });
  });
}
