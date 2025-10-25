import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';

class FirestoreGroupMapper {
  static Group fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<GroupMember>? members,
  }) {
    final data = doc.data();
    return Group(
      id: doc.id,
      ownerId: data?['ownerId'] as String? ?? '',
      name: data?['name'] as String? ?? '',
      memo: data?['memo'] as String?,
      members: members ?? const [],
    );
  }

  static Map<String, dynamic> toFirestore(Group group) {
    return {
      'ownerId': group.ownerId,
      'name': group.name,
      'memo': group.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
