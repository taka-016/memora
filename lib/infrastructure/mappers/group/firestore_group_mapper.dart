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
      version: groupData['version'] as int?,
      id: groupDoc.id,
      ownerId: groupData['ownerId'] as String? ?? '',
      color: groupData['color'] as String? ?? '#4CAF50',
      name: groupData['name'] as String? ?? '',
      memo: groupData['memo'] as String?,
      members: members,
    );
  }

  static Map<String, dynamic> toCreateFirestore(Group group) {
    return {
      'ownerId': group.ownerId,
      'color': group.color,
      'name': group.name,
      'memo': group.memo,
      'version': 1,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }

  static Map<String, dynamic> toUpdateFirestore(Group group) {
    return {
      'ownerId': group.ownerId,
      'color': group.color,
      'name': group.name,
      'memo': group.memo,
      'version': group.version == null ? null : group.version! + 1,
      ...FirestoreWriteMetadata.forUpdate(),
    };
  }
}
