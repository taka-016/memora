import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  final start = DateTime.utc(2026, 10, 2);
  for (final allDay in [false, true]) {
    for (final individual in [false]) {
      Object create(int minutes) => CalendarEvent(
        id: 'event',
        groupId: 'group',
        title: '予定',
        startDateTime: start,
        endDateTime: start,
        isAllDay: allDay,
        labelType: 'group',
        notificationMinutesBefore: [minutes],
      );
      test('通知は上限ちょうどまで許可し超過を拒否する（終日: $allDay・個別回: $individual）', () {
        final maximum = allDay ? 40320 : 10080;
        expect(() => create(maximum), returnsNormally);
        expect(
          () => create(maximum + (allDay ? 1440 : 1)),
          throwsA(isA<ValidationException>()),
        );
      });
    }
  }
}
