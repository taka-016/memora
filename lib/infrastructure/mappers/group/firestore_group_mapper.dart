import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group/group.dart';

class FirestoreGroupMapper {
  static Map<String, dynamic> toFirestore(Group group) {
    return {
      'ownerId': group.ownerId,
      'name': group.name,
      'memo': group.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
