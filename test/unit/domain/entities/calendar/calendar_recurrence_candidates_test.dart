import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';

void main() {
  test('古い年次系列の候補を年の間隔で生成する', () {
    final rule = CalendarRecurrenceRule.parse('FREQ=YEARLY;COUNT=1000');
    final days = rule.candidateDays(
      DateTime.utc(1900, 10, 4),
      DateTime.utc(2026, 10),
      DateTime.utc(2026, 11),
    );
    expect(days.toList(), [DateTime.utc(2026, 10, 4)]);
  });

  test('候補期間の途中からでも日と週の間隔を初回から維持する', () {
    final start = DateTime.utc(2026, 1, 7);
    expect(
      CalendarRecurrenceRule.parse('FREQ=DAILY;INTERVAL=3')
          .candidateDays(
            start,
            DateTime.utc(2026, 1, 8),
            DateTime.utc(2026, 1, 15),
          )
          .toList(),
      [DateTime.utc(2026, 1, 10), DateTime.utc(2026, 1, 13)],
    );
    expect(
      CalendarRecurrenceRule.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=WE,MO')
          .candidateDays(start, start, DateTime.utc(2026, 2))
          .toList(),
      [
        DateTime.utc(2026, 1, 7),
        DateTime.utc(2026, 1, 19),
        DateTime.utc(2026, 1, 21),
      ],
    );
  });

  test('月末と閏日の欠落は次の有効な候補まで飛ばす', () {
    expect(
      CalendarRecurrenceRule.parse('FREQ=MONTHLY;INTERVAL=2')
          .candidateDays(
            DateTime.utc(2026, 7, 31),
            DateTime.utc(2026, 8),
            DateTime.utc(2027, 2),
          )
          .toList(),
      [DateTime.utc(2027, 1, 31)],
    );
    expect(
      CalendarRecurrenceRule.parse('FREQ=YEARLY')
          .candidateDays(
            DateTime.utc(2024, 2, 29),
            DateTime.utc(2025),
            DateTime.utc(2029),
          )
          .toList(),
      [DateTime.utc(2028, 2, 29)],
    );
  });

  test('第5曜日と最終曜日の候補を月単位で生成する', () {
    expect(
      CalendarRecurrenceRule.parse('FREQ=MONTHLY;BYDAY=5MO')
          .candidateDays(
            DateTime.utc(2026, 3, 30),
            DateTime.utc(2026, 4),
            DateTime.utc(2026, 7),
          )
          .toList(),
      [DateTime.utc(2026, 6, 29)],
    );
    expect(
      CalendarRecurrenceRule.parse('FREQ=MONTHLY;BYDAY=-1FR')
          .candidateDays(
            DateTime.utc(2026, 1, 30),
            DateTime.utc(2026, 2),
            DateTime.utc(2026, 4),
          )
          .toList(),
      [DateTime.utc(2026, 2, 27), DateTime.utc(2026, 3, 27)],
    );
  });
}
