import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreGroupMapper {
  static GroupDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> groupDoc, {
    List<GroupMemberDto> members = const [],
  }) {
    final groupData = groupDoc.data() ?? {};
    return GroupDto(
      id: groupDoc.id,
      ownerId: groupData['ownerId'] as String? ?? '',
      name: groupData['name'] as String? ?? '',
      memo: groupData['memo'] as String?,
      members: members,
    );
  }

  static Map<String, dynamic> toCreateFirestore(Group group) {
    return {
      'ownerId': group.ownerId,
      'name': group.name,
      'memo': group.memo,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(Group group) {
    return {
      'ownerId': group.ownerId,
      'name': group.name,
      'memo': group.memo,
      ...FirestoreWriteMetadata.forUpdate(),
    };
  }
}
