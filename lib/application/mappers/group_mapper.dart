import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/mappers/group_member_mapper.dart';
import 'package:memora/domain/entities/group.dart';

class GroupMapper {
  static GroupDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> groupDoc, {
    List<GroupMemberDto> members = const [],
  }) {
    final groupData = groupDoc.data();
    return GroupDto(
      id: groupDoc.id,
      ownerId: groupData?['ownerId'] as String? ?? '',
      name: groupData?['name'] as String? ?? '',
      memo: groupData?['memo'] as String?,
      members: members,
    );
  }

  static Group toEntity(GroupDto dto) {
    return Group(
      id: dto.id,
      ownerId: dto.ownerId,
      name: dto.name,
      memo: dto.memo,
      members: GroupMemberMapper.toEntityList(dto.members),
    );
  }

  static List<Group> toEntityList(List<GroupDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
