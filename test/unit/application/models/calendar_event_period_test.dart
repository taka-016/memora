import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/calendar_event_period.dart';

void main() {
  test('月表示は隣接月のグリッドを含み過去の月へ移動すれば取得期間も移る', () {
    final period = CalendarEventPeriod.forMonth(DateTime(2026, 11, 10));
    expect(period.from, DateTime(2026, 10, -6));
    expect(period.to, DateTime(2027, 1, 8));
    final past = CalendarEventPeriod.forMonth(DateTime(2021, 11));
    expect(past.from, DateTime(2021, 10, -6));
  });

  test('通知は当日以降を対象とし28日先の通知と最大4週間前の通知指定を含む', () {
    final now = DateTime(2026, 11, 10, 15);
    final period = CalendarEventPeriod.forNotifications(now);
    expect(period.from, DateTime(2026, 11, 10));
    expect(period.to.isAfter(now.add(const Duration(days: 56))), isTrue);
    expect(period.to.isBefore(now.add(const Duration(days: 60))), isTrue);
  });

  test('終日のUTC日付と時刻付き予定の実時刻の両方を取得範囲に含む', () {
    final period = CalendarEventPeriod(
      from: DateTime(2026, 11, 10),
      to: DateTime(2026, 11, 11),
    );
    expect(period.queryFrom.isAfter(period.from), isFalse);
    expect(period.queryFrom.isAfter(DateTime.utc(2026, 11, 10)), isFalse);
    expect(period.queryTo.isBefore(period.to), isFalse);
    expect(period.queryTo.isBefore(DateTime.utc(2026, 11, 11)), isFalse);
  });
}
