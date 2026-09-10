import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';

class SqliteGroupMemberMapper {
  static GroupMemberDto fromRow(Map<String, Object?> row, MemberDto member) =>
      GroupMemberDto(
        groupId: row['group_id'] as String,
        memberId: row['member_id'] as String,
        isAdministrator: row['is_administrator'] == 1,
        orderIndex: row['order_index'] as int,
        accountId: member.accountId,
        ownerId: member.ownerId,
        hiraganaFirstName: member.hiraganaFirstName,
        hiraganaLastName: member.hiraganaLastName,
        kanjiFirstName: member.kanjiFirstName,
        kanjiLastName: member.kanjiLastName,
        firstName: member.firstName,
        lastName: member.lastName,
        displayName: member.displayName,
        type: member.type,
        birthday: member.birthday,
        gender: member.gender,
        email: member.email,
        phoneNumber: member.phoneNumber,
      );
  static Map<String, Object?> toRow(GroupMember value) => {
    'group_id': value.groupId,
    'member_id': value.memberId,
    'is_administrator': value.isAdministrator ? 1 : 0,
    'order_index': value.orderIndex,
  };
}
