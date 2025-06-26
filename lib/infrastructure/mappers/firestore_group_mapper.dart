import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/group.dart';

class FirestoreGroupMapper {
  static Group fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Group(
      id: doc.id,
      administratorId: data?['administratorId'] as String? ?? '',
      name: data?['name'] as String? ?? '',
      memo: data?['memo'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(Group group) {
    return {
      'administratorId': group.administratorId,
      'name': group.name,
      'memo': group.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
