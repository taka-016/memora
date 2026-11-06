import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';

void main() {
  test('終日を先頭にし終日同士と時刻付き同士を開始日時順に表示する', () {
    CalendarEventDto event(
      String id,
      DateTime start,
      DateTime end,
      bool allDay,
    ) => CalendarEventDto(
      id: id,
      groupId: 'g',
      title: id,
      startDateTime: start,
      endDateTime: end,
      isAllDay: allDay,
    );
    final state = CalendarState(
      selectedDate: DateTime(2026, 11, 2),
      events: [
        event('朝', DateTime(2026, 11, 2, 1), DateTime(2026, 11, 2, 2), false),
        event(
          '終日当日',
          DateTime.utc(2026, 11, 2),
          DateTime.utc(2026, 11, 3),
          true,
        ),
        event(
          '前日開始',
          DateTime(2026, 11, 1, 20),
          DateTime(2026, 11, 2, 12),
          false,
        ),
        event(
          '終日前日',
          DateTime.utc(2026, 11, 1),
          DateTime.utc(2026, 11, 3),
          true,
        ),
      ],
    );
    expect(state.eventsForDay(DateTime(2026, 11, 2)).map((event) => event.id), [
      '終日前日',
      '終日当日',
      '前日開始',
      '朝',
    ]);
  });
}
