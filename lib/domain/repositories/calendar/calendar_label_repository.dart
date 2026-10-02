import 'package:memora/domain/entities/calendar/calendar_label.dart';

abstract class CalendarLabelRepository {
  Future<String> saveCalendarLabel(CalendarLabel label);
  Future<void> deleteCalendarLabel(String labelId);
}
