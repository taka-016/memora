// ignore_for_file: constant_identifier_names

import 'package:memora/domain/exceptions/validation_exception.dart';

const MAX_CALENDAR_NOTIFICATIONS = 5;
const MAX_TIMED_CALENDAR_NOTIFICATION_MINUTES = 7 * 24 * 60;
const MAX_ALL_DAY_CALENDAR_NOTIFICATION_MINUTES = 4 * 7 * 24 * 60;

void validateCalendarNotifications(List<int> values, bool allDay) {
  if (values.length > MAX_CALENDAR_NOTIFICATIONS ||
      values.toSet().length != values.length ||
      values.any((v) => v < 0 || (allDay && v % 1440 != 0))) {
    throw ValidationException(
      '通知は重複なしで最大$MAX_CALENDAR_NOTIFICATIONS件、終日は日・週単位で指定してください',
    );
  }
  final maximum = allDay
      ? MAX_ALL_DAY_CALENDAR_NOTIFICATION_MINUTES
      : MAX_TIMED_CALENDAR_NOTIFICATION_MINUTES;
  if (values.any((value) => value > maximum)) {
    throw ValidationException(
      allDay ? '終日の通知は4週間前まで指定できます' : '時間指定の通知は1週間前まで指定できます',
    );
  }
}
