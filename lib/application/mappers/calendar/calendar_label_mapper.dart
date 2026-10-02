import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';

class CalendarLabelMapper {
  static CalendarLabel toEntity(CalendarLabelDto value) {
    return CalendarLabel(
      id: value.id,
      groupId: value.groupId,
      name: value.name,
      color: value.color,
    );
  }

  static CalendarLabelDto toDto(CalendarLabel value) {
    return CalendarLabelDto(
      id: value.id,
      groupId: value.groupId,
      name: value.name,
      color: value.color,
    );
  }
}
