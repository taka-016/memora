import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';

class SqliteMemberEventMapper {
  static MemberEventDto fromRow(Map<String, Object?> row) => MemberEventDto(
    id: row['id'] as String,
    memberId: row['member_id'] as String,
    year: row['year'] as int,
    memo: row['memo'] as String,
  );
  static Map<String, Object?> toRow(MemberEvent value) => {
    'id': value.id,
    'member_id': value.memberId,
    'year': value.year,
    'memo': value.memo,
  };
}
