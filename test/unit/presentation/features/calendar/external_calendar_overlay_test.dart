import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/presentation/features/calendar/external_calendar_overlay.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/presentation/notifiers/calendar/external_calendar_state.dart';

void main() {
  test('同じカレンダーと予定を複数アカウントから取得しても識別子が衝突しない', () {
    const calendar = ExternalCalendarDto(id: 'shared', name: '共有');
    final external = ExternalCalendarState(
      month: DateTime(2026, 11),
      connections: [
        for (final id in ['first', 'second'])
          ExternalCalendarConnection(
            account: ExternalCalendarAccount(id: id, name: '$id@example.com'),
          ),
      ],
      calendarsByAccount: {
        'first': [calendar],
        'second': [calendar],
      },
      eventsByAccount: {
        for (final account in ['first', 'second'])
          account: [
            ExternalCalendarEventDto(
              accountId: account,
              id: 'same-event',
              calendarId: 'shared',
              calendarName: '共有',
              title: '$accountの予定',
              startDateTime: DateTime(2026, 11, 2, 9),
              endDateTime: DateTime(2026, 11, 2, 10),
              isAllDay: false,
            ),
          ],
      },
    );
    final result = overlayExternalCalendar(
      CalendarState(selectedDate: DateTime(2026, 11)),
      external,
    );
    expect(result.events.map((v) => v.title), ['firstの予定', 'secondの予定']);
    expect(result.labels.map((v) => v.name), [
      '端末-first@example.com',
      '端末-second@example.com',
    ]);
    expect(result.events.map((v) => v.id).toSet(), hasLength(2));
    expect(result.labels.map((v) => v.id).toSet(), hasLength(2));
    expect(result.events.first.labelId, result.labels.first.id);
    expect(result.events.last.labelId, result.labels.last.id);
  });
}
