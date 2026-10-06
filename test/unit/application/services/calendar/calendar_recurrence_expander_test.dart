import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/services/calendar/calendar_time_zone.dart';

import 'calendar_recurrence_expander_test.mocks.dart';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_event_override.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';

@GenerateMocks([CalendarTimeZone])
void main() {
  final expander = CalendarRecurrenceExpander(IanaCalendarTimeZone());
  CalendarEventDto event(
    String rule,
    DateTime start, {
    bool allDay = true,
    String zone = 'America/New_York',
    List<CalendarEventOverride> overrides = const [],
    Duration duration = Duration.zero,
  }) => CalendarEventDto(
    id: 'series',
    groupId: 'family',
    labelId: 'label',
    title: '予定',
    startDateTime: start,
    endDateTime: start.add(duration),
    isAllDay: allDay,
    recurrenceRule: rule,
    timeZone: allDay ? null : zone,
    overrides: overrides,
  );
  List<CalendarEventDto> expand(
    CalendarEventDto value,
    DateTime from,
    DateTime to,
  ) => expander.expand(value, from, to);

  for (final frequency in ['DAILY', 'WEEKLY']) {
    test('古い$frequency系列は表示前を解決せずCOUNT終了と個別回を判定する', () {
      final zone = MockCalendarTimeZone();
      when(zone.local(any, any))
          .thenAnswer((call) => call.positionalArguments[0] as DateTime);
      when(zone.resolve(any, any))
          .thenAnswer((call) => call.positionalArguments[0] as DateTime);
      when(zone.skippedDates(any, any, any)).thenReturn([]);
      final start = DateTime.utc(1900, 1, 1, 9);
      final value = event(
        'FREQ=$frequency;COUNT=1000000',
        start,
        allDay: false,
        zone: 'UTC',
      );
      final fast = CalendarRecurrenceExpander(zone);
      final result = fast.expand(
        value,
        DateTime.utc(2026),
        DateTime.utc(2026, 2),
      );
      expect(result.length, frequency == 'DAILY' ? 31 : 4);
      final resolutions = verify(zone.resolve(captureAny, 'UTC')).captured;
      expect(resolutions.length, lessThan(40));
      final expired = value.copyWith(
        recurrenceRule: 'FREQ=$frequency;COUNT=10',
      );
      expect(
        fast.expand(expired, DateTime.utc(2026), DateTime.utc(2026, 2)),
        isEmpty,
      );
      final invalid = expired.copyWith(
        overrides: [
          CalendarEventOverride(
            originalStartDateTime: DateTime.utc(
              2026,
              1,
              frequency == 'DAILY' ? 1 : 5,
              9,
            ),
            isCancelled: true,
          ),
        ],
      );
      expect(
        fast.expand(invalid, DateTime.utc(2026), DateTime.utc(2026, 2)),
        isEmpty,
      );
      expect(
        verify(zone.resolve(captureAny, 'UTC')).captured.length,
        lessThan(10),
      );
    });
  }

  test('表示前の夏時間欠落をCOUNTに含めず残りの回を表示する', () {
    final value = event(
      'FREQ=DAILY;COUNT=4',
      DateTime.utc(2026, 3, 7, 7, 30),
      allDay: false,
    );
    expect(
      expand(
        value,
        DateTime.utc(2026, 3, 10),
        DateTime.utc(2026, 3, 14),
      ).map((v) => v.startDateTime.toUtc()),
      [DateTime.utc(2026, 3, 10, 6, 30), DateTime.utc(2026, 3, 11, 6, 30)],
    );
  });

  test('間隔と複数曜日を月曜起点で計算し初回を含む回数で終了する', () {
    final values = expand(
      event(
        'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;COUNT=4',
        DateTime.utc(2026, 1, 5),
      ),
      DateTime.utc(2026),
      DateTime.utc(2026, 2),
    );
    expect(values.map((v) => v.startDateTime.day), [5, 7, 19, 21]);
  });
  test('存在しない月末とうるう日はスキップし回数に含めない', () {
    expect(
      expand(
        event('FREQ=MONTHLY;COUNT=3', DateTime.utc(2026, 1, 31)),
        DateTime.utc(2026),
        DateTime.utc(2026, 7),
      ).map((v) => v.startDateTime.month),
      [1, 3, 5],
    );
    expect(
      expand(
        event('FREQ=YEARLY;COUNT=2', DateTime.utc(2024, 2, 29)),
        DateTime.utc(2024),
        DateTime.utc(2029),
      ).map((v) => v.startDateTime.year),
      [2024, 2028],
    );
  });
  test('第2火曜日と最終金曜日と日付指定を展開する', () {
    for (final entry in {
      '2TU': [13, 10, 10],
      '-1FR': [30, 27, 27],
    }.entries) {
      final start = DateTime.utc(2026, 1, entry.value.first);
      expect(
        expand(
          event('FREQ=MONTHLY;BYDAY=${entry.key};COUNT=3', start),
          DateTime.utc(2026),
          DateTime.utc(2026, 4),
        ).map((v) => v.startDateTime.day),
        entry.value,
      );
    }
    expect(
      expand(
        event('FREQ=MONTHLY;BYMONTHDAY=15;COUNT=2', DateTime.utc(2026, 1, 15)),
        DateTime.utc(2026),
        DateTime.utc(2026, 3),
      ).map((v) => v.startDateTime.day),
      [15, 15],
    );
  });
  test('終了日を含み複数日の重なりと無期限の表示期間だけを返す', () {
    final value = event(
      'FREQ=DAILY;INTERVAL=2;UNTIL=20260105',
      DateTime.utc(2026, 1, 1),
      duration: const Duration(days: 2),
    );
    expect(
      expand(
        value,
        DateTime.utc(2026, 1, 3),
        DateTime.utc(2026, 1, 8),
      ).map((v) => v.startDateTime.day),
      [1, 3, 5],
    );
    expect(
      expand(
        event('FREQ=DAILY', DateTime.utc(2000)),
        DateTime.utc(2050, 1, 1),
        DateTime.utc(2050, 1, 4),
      ).length,
      3,
    );
  });
  test('個別回を別月に移しても元の回を表示せず取消しも反映する', () {
    final moved = CalendarEventOverride(
      originalStartDateTime: DateTime.utc(2026, 1, 2),
      isCancelled: false,
      title: '移動',
      startDateTime: DateTime.utc(2026, 2, 5),
      endDateTime: DateTime.utc(2026, 2, 6),
      isAllDay: true,
      labelId: 'label',
    );
    final cancelled = CalendarEventOverride(
      originalStartDateTime: DateTime.utc(2026, 1, 3),
      isCancelled: true,
    );
    final value = event(
      'FREQ=DAILY;COUNT=3',
      DateTime.utc(2026, 1, 1),
      overrides: [moved, cancelled],
    );
    expect(expand(value, DateTime.utc(2026), DateTime.utc(2026, 2)).length, 1);
    final february = expand(
      value,
      DateTime.utc(2026, 2),
      DateTime.utc(2026, 3),
    );
    expect(february.single.title, '移動');
    expect(february.single.originalStartDateTime, DateTime.utc(2026, 1, 2));
  });
  test('系列の現地時刻を保ち夏時間の欠落はスキップし重複は早い方を1回にする', () {
    final spring = expand(
      event(
        'FREQ=DAILY;COUNT=3',
        DateTime.utc(2026, 3, 7, 7, 30),
        allDay: false,
      ),
      DateTime.utc(2026, 3, 7),
      DateTime.utc(2026, 3, 12),
    );
    expect(spring.map((v) => v.startDateTime.toUtc()), [
      DateTime.utc(2026, 3, 7, 7, 30),
      DateTime.utc(2026, 3, 9, 6, 30),
      DateTime.utc(2026, 3, 10, 6, 30),
    ]);
    final autumn = expand(
      event(
        'FREQ=DAILY;COUNT=3',
        DateTime.utc(2026, 10, 31, 5, 30),
        allDay: false,
      ),
      DateTime.utc(2026, 10, 31),
      DateTime.utc(2026, 11, 4),
    );
    expect(autumn.map((v) => v.startDateTime.toUtc()), [
      DateTime.utc(2026, 10, 31, 5, 30),
      DateTime.utc(2026, 11, 1, 5, 30),
      DateTime.utc(2026, 11, 2, 6, 30),
    ]);
  });
  test('終了条件から外れた個別取消しを維持し開始日に一致しない条件を拒否する', () {
    final invalid = event(
      'FREQ=DAILY;COUNT=2',
      DateTime.utc(2026),
      overrides: [
        CalendarEventOverride(
          originalStartDateTime: DateTime.utc(2026, 1, 3),
          isCancelled: true,
        ),
      ],
    );
    expect(
      expand(invalid, DateTime.utc(2026), DateTime.utc(2026, 2)),
      hasLength(2),
    );
    expect(
      () => expand(
        event('FREQ=WEEKLY;BYDAY=TU', DateTime.utc(2026, 1, 5)),
        DateTime.utc(2026),
        DateTime.utc(2026, 2),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
  test('時刻付きのUTC終了条件は系列の現地時刻ではなく実時刻で比較する', () {
    final value = event(
      'FREQ=DAILY;UNTIL=20260101T010000Z',
      DateTime.utc(2026, 1, 1, 0),
      allDay: false,
      zone: 'Asia/Tokyo',
    );
    expect(
      expand(value, DateTime.utc(2026), DateTime.utc(2026, 1, 3)).length,
      1,
    );
  });

  test('終日の終了条件は時刻を無視し指定日を含む', () {
    expect(
      () => CalendarEvent(
        id: '',
        groupId: 'family',
        labelId: 'label',
        title: '予定',
        startDateTime: DateTime(2026, 1, 1, 15),
        endDateTime: DateTime(2026, 1, 1, 16),
        isAllDay: true,
        recurrenceRule: 'FREQ=DAILY;INTERVAL=2;UNTIL=20260101',
      ),
      returnsNormally,
    );
  });

  test('重複する時刻の遅い方を初回に指定すると保存前の展開で拒否する', () {
    final value = event(
      'FREQ=DAILY;COUNT=1',
      DateTime.utc(2026, 11, 1, 6, 30),
      allDay: false,
    );
    expect(
      () => expand(value, DateTime.utc(2026, 11), DateTime.utc(2026, 11, 3)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('終日の個別回キーは端末ローカル時刻ではなく日付として扱う', () {
    final value = event(
      'FREQ=DAILY;COUNT=3',
      DateTime(2026, 1, 1),
      overrides: [
        CalendarEventOverride(
          originalStartDateTime: DateTime(2026, 1, 2),
          isCancelled: true,
        ),
      ],
    );
    expect(
      expand(
        value,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 4),
      ).map((v) => v.startDateTime.day),
      [1, 3],
    );
  });

  test('時刻付きの終了条件はRFCに従いUTC日時だけを受理する', () {
    expect(
      () => CalendarEvent(
        id: '',
        groupId: 'family',
        labelId: 'label',
        title: '予定',
        startDateTime: DateTime.utc(2026, 1, 1),
        endDateTime: DateTime.utc(2026, 1, 1, 1),
        isAllDay: false,
        timeZone: 'Asia/Tokyo',
        recurrenceRule: 'FREQ=DAILY;UNTIL=20260101',
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('不正な繰り返し設定を保存前に拒否する', () {
    for (final rule in [
      'FREQ=DAILY;INTERVAL=0',
      'FREQ=DAILY;COUNT=0',
      'FREQ=DAILY;COUNT=2;UNTIL=20260105',
      'FREQ=WEEKLY;BYDAY=',
      'FREQ=DAILY;UNTIL=20251231',
      'FREQ=HOURLY',
      'FREQ=DAILY;BOGUS=1',
    ]) {
      expect(
        () => CalendarEvent(
          id: '',
          groupId: 'family',
          labelId: 'label',
          title: '予定',
          startDateTime: DateTime.utc(2026),
          endDateTime: DateTime.utc(2026),
          isAllDay: true,
          recurrenceRule: rule,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });
}
