import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/domain/entities/group_member.dart';

class GroupMemberMapper {
  static GroupMemberDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> groupMemberDoc,
    DocumentSnapshot<Map<String, dynamic>> memberDoc,
  ) {
    final groupMemberData = groupMemberDoc.data();
    final memberData = memberDoc.data();
    return GroupMemberDto(
      memberId: memberDoc.id,
      groupId: groupMemberData!['groupId'] as String,
      isAdministrator: groupMemberData['isAdministrator'] as bool? ?? false,
      accountId: memberData?['accountId'] as String?,
      ownerId: memberData?['ownerId'] as String?,
      hiraganaFirstName: memberData?['hiraganaFirstName'] as String?,
      hiraganaLastName: memberData?['hiraganaLastName'] as String?,
      kanjiFirstName: memberData?['kanjiFirstName'] as String?,
      kanjiLastName: memberData?['kanjiLastName'] as String?,
      firstName: memberData?['firstName'] as String?,
      lastName: memberData?['lastName'] as String?,
      displayName: memberData?['displayName'] as String? ?? '',
      type: memberData?['type'] as String?,
      birthday: (memberData?['birthday'] as Timestamp?)?.toDate(),
      gender: memberData?['gender'] as String?,
      email: memberData?['email'] as String?,
      phoneNumber: memberData?['phoneNumber'] as String?,
      passportNumber: memberData?['passportNumber'] as String?,
      passportExpiration: memberData?['passportExpiration'] as String?,
    );
  }

  static GroupMember toEntity(GroupMemberDto dto) {
    return GroupMember(
      groupId: dto.groupId,
      memberId: dto.memberId,
      isAdministrator: dto.isAdministrator,
    );
  }

  static List<GroupMember> toEntityList(List<GroupMemberDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
