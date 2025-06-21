import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/managed_member.dart';

class FirestoreManagedMemberMapper {
  static ManagedMember fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ManagedMember(
      id: doc.id,
      memberId: data?['memberId'] as String? ?? '',
      managedMemberId: data?['managedMemberId'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toFirestore(ManagedMember managedMember) {
    return {
      'memberId': managedMember.memberId,
      'managedMemberId': managedMember.managedMemberId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
