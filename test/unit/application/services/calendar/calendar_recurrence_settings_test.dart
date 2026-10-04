import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_settings.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

void main() {
  final expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());
  final start = DateTime.utc(2026, 1, 5);
  String? rule(CalendarRecurrenceSettings settings, {bool allDay = true}) =>
      settings.toRule(
        start: start,
        allDay: allDay,
        zone: 'Asia/Tokyo',
        expander: expander,
      );
  test('2週間ごとの複数曜日と回数を要約し保存形式へ変換する', () {
    const settings = CalendarRecurrenceSettings(
      frequency: 'WEEKLY',
      interval: 2,
      weekdays: [1, 3],
      count: 10,
    );
    expect(settings.summary, '2週間ごとの月・水曜日、10回');
    expect(rule(settings), 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=10');
    expect(
      CalendarRecurrenceSettings.fromRule(rule(settings), start).summary,
      settings.summary,
    );
  });
  test('各プリセットは単発・毎日・毎週・毎月・毎年・平日を表す', () {
    for (final entry in {
      'none': null,
      'daily': 'FREQ=DAILY',
      'weekly': 'FREQ=WEEKLY;BYDAY=MO',
      'monthly': 'FREQ=MONTHLY;BYMONTHDAY=5',
      'yearly': 'FREQ=YEARLY',
      'weekdays': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
    }.entries) {
      expect(
        rule(CalendarRecurrenceSettings.preset(entry.key, start)),
        entry.value,
      );
    }
  });
  test('月末・最終曜日・うるう年の設定を実際の回へ展開する', () {
    for (final entry in <CalendarRecurrenceSettings, DateTime>{
      const CalendarRecurrenceSettings(
        frequency: 'MONTHLY',
        monthDay: 31,
        count: 3,
      ): DateTime.utc(
        2026,
        1,
        31,
      ),
      const CalendarRecurrenceSettings(
        frequency: 'MONTHLY',
        weekdays: [5],
        ordinal: -1,
        count: 3,
      ): DateTime.utc(
        2026,
        1,
        30,
      ),
      const CalendarRecurrenceSettings(frequency: 'YEARLY', count: 3):
          DateTime.utc(2024, 2, 29),
    }.entries) {
      final dto = CalendarEventDto(
        id: 'e',
        groupId: 'g',
        labelId: 'l',
        title: '予定',
        startDateTime: entry.value,
        endDateTime: entry.value.add(const Duration(days: 2)),
        isAllDay: true,
        recurrenceRule: entry.key.toRule(
          start: entry.value,
          allDay: true,
          zone: 'UTC',
          expander: expander,
        ),
      );
      final values = expander.expand(
        dto,
        DateTime.utc(2024),
        DateTime.utc(2033),
      );
      expect(values, hasLength(3));
      expect(
        values.every(
          (v) => v.endDateTime.difference(v.startDateTime).inDays == 2,
        ),
        isTrue,
      );
    }
  });
  test('時刻付きの終了日は系列のタイムゾーンでその日の末尾へ変換する', () {
    final settings = CalendarRecurrenceSettings(
      frequency: 'DAILY',
      until: DateTime.utc(2026, 1, 7),
    );
    expect(rule(settings, allDay: false), 'FREQ=DAILY;UNTIL=20260107T145959Z');
    expect(
      CalendarRecurrenceSettings.fromRule(
        rule(settings, allDay: false),
        start,
        zone: 'Asia/Tokyo',
        expander: expander,
      ).summary,
      '毎日、2026/1/7まで',
    );
  });
  test('無効な間隔・終了条件・曜日と開始日の不一致を拒否する', () {
    for (final settings in [
      const CalendarRecurrenceSettings(frequency: 'DAILY', interval: 0),
      const CalendarRecurrenceSettings(frequency: 'DAILY', count: 0),
      CalendarRecurrenceSettings(frequency: 'DAILY', until: DateTime.utc(2025)),
      CalendarRecurrenceSettings(frequency: 'DAILY', count: 2, until: start),
      const CalendarRecurrenceSettings(frequency: 'WEEKLY', weekdays: [2]),
    ]) {
      expect(
        () => rule(settings),
        throwsA(isA<ApplicationValidationException>()),
      );
    }
  });
}
