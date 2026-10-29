import 'package:memora/domain/exceptions/validation_exception.dart';

const MAX_CALENDAR_NOTIFICATIONS = 5;

void validateCalendarNotifications(List<int> values, bool allDay) {
  if (values.length > MAX_CALENDAR_NOTIFICATIONS ||
      values.toSet().length != values.length ||
      values.any((v) => v < 0 || (allDay && v % 1440 != 0))) {
    throw ValidationException(
      '通知は重複なしで最大$MAX_CALENDAR_NOTIFICATIONS件、終日は日・週単位で指定してください',
    );
  }
}
