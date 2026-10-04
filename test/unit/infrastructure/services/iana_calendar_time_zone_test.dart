import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

void main() {
  test('夏時間の欠落時刻だけを数え重複時刻は除外しない', () {
    final zone = IanaCalendarTimeZone();
    expect(
      zone.skippedDates(
        DateTime.utc(2026, 3, 1, 2, 30),
        DateTime.utc(2026, 4),
        'America/New_York',
      ),
      [DateTime.utc(2026, 3, 8)],
    );
    expect(
      zone.skippedDates(
        DateTime.utc(2026, 10, 1, 1, 30),
        DateTime.utc(2026, 12),
        'America/New_York',
      ),
      isEmpty,
    );
  });
  test('日付変更線の変更で欠落した日付も数える', () {
    final zone = IanaCalendarTimeZone();
    expect(
      zone.skippedDates(
        DateTime.utc(2011, 12, 1, 12),
        DateTime.utc(2012),
        'Pacific/Apia',
      ),
      [DateTime.utc(2011, 12, 30)],
    );
  });
}
