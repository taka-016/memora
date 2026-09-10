import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';

class SqliteGroupEventMapper {
  static GroupEventDto fromRow(Map<String, Object?> row) => GroupEventDto(
id: row['id'] as String,
groupId: row['group_id'] as String,
year: row['year'] as int,
memo: row['memo'] as String
);
  static Map<String, Object?> toRow(GroupEvent value) => {
'id': value.id,
'group_id': value.groupId,
'year': value.year,
'memo': value.memo,
};
}
