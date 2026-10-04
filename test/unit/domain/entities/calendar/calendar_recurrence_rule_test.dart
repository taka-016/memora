import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_recurrence_rule.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  test('日次と週次の表示前候補数を初回と間隔から数える', () {
    final start = DateTime.utc(1900, 1, 1);
    final before = DateTime.utc(2026, 1, 1);
    expect(
      CalendarRecurrenceRule.parse('FREQ=DAILY;INTERVAL=2')
          .candidateCountBefore(start, before),
      23011,
    );
    expect(
      CalendarRecurrenceRule.parse('FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE')
          .candidateCountBefore(start, before),
      6576,
    );
    expect(
      CalendarRecurrenceRule.parse('FREQ=DAILY')
          .candidateCountBefore(start, start),
      0,
    );
  });

  test('UNTILの年月日と時分秒の範囲外を正規化して受理しない', () {
    for (final value in [
      '20260101T126000Z',
      '20260101T125960Z',
      '20260101T006000Z',
      '20260101T240000Z',
      '20260101T129900Z',
      '20260101T120099Z',
      '20260230T120000Z',
      '20261301',
      '20260230',
    ]) {
      expect(
        () => CalendarRecurrenceRule.parse('FREQ=DAILY;UNTIL=$value'),
        throwsA(isA<ValidationException>()),
        reason: value,
      );
    }
  });

  test('UNTILの有効な閏日と時刻の上下限を維持する', () {
    for (final entry in {
      '20240229': DateTime.utc(2024, 2, 29),
      '20260101T000000Z': DateTime.utc(2026),
      '20260101T235959Z': DateTime.utc(2026, 1, 1, 23, 59, 59),
    }.entries) {
      expect(
        CalendarRecurrenceRule.parse('FREQ=DAILY;UNTIL=${entry.key}').until,
        entry.value,
      );
    }
  });
}
