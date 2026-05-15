import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/time/app_clock.dart';

void main() {
  group('NtpSynchronizedAppClock', () {
    test('同期直後はNTP時刻をUTCで返す', () async {
      var systemNow = DateTime.utc(2026, 5, 14, 10);
      final clock = NtpSynchronizedAppClock(
        systemNow: () => systemNow,
        fetchNtpTime: () async => DateTime.utc(2026, 5, 14, 10, 5),
      );

      await clock.sync();

      final difference = clock
          .nowUtc()
          .difference(DateTime.utc(2026, 5, 14, 10, 5))
          .abs();
      expect(difference, lessThan(const Duration(seconds: 1)));
      expect(clock.nowUtc().isUtc, isTrue);
    });

    test('同期後に端末時計が変更されてもNTP時刻から進める', () async {
      var systemNow = DateTime.utc(2026, 5, 14, 10);
      final clock = NtpSynchronizedAppClock(
        systemNow: () => systemNow,
        fetchNtpTime: () async => DateTime.utc(2026, 5, 14, 10, 5),
      );

      await clock.sync();
      systemNow = DateTime.utc(2026, 5, 15, 10);

      final difference = clock
          .nowUtc()
          .difference(DateTime.utc(2026, 5, 14, 10, 5))
          .abs();
      expect(difference, lessThan(const Duration(seconds: 1)));
    });

    test('固定時刻に差し替えられる', () {
      final fixed = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final clock = FixedAppClock(fixed);

      expect(clock.nowUtc(), fixed);
      expect(clock.nowLocal(), fixed.toLocal());
    });
  });
}
