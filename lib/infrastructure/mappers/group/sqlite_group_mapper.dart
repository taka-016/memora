import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';

class SqliteGroupMapper {
  static GroupDto fromRow(
    Map<String, Object?> row, {
    List<GroupMemberDto> members = const [],
  }) => GroupDto(
    id: row['id'] as String,
    ownerId: row['owner_id'] as String,
    textColor: row['text_color'] as String?,
    color: row['color'] as String? ?? '#4CAF50',
    name: row['name'] as String,
    memo: row['memo'] as String?,
    members: members,
  );
  static Map<String, Object?> toRow(Group value) => {
    'id': value.id,
    'owner_id': value.ownerId,
    'color': value.color,
    'text_color': value.textColor,
    'name': value.name,
    'memo': value.memo,
  };
}
