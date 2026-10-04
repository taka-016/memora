import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/application/dtos/calendar/calendar_label_dto.dart';

class SqliteCalendarLabelMapper {
  static CalendarLabelDto fromRow(Map<String, Object?> row) => CalendarLabelDto(
    id: row['id'] as String,
    groupId: row['group_id'] as String,
    name: row['name'] as String,
    color: row['color'] as String,
    textColor: row['text_color'] as String,
    sortOrder: row['sort_order'] as int,
  );
  static Map<String, Object?> toRow(CalendarLabel value) => {
    'id': value.id,
    'group_id': value.groupId,
    'name': value.name,
    'color': value.color,
    'text_color': value.textColor,
    'sort_order': value.sortOrder,
  };
}
