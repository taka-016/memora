import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreCalendarMembership {
  FirestoreCalendarMembership(this._firestore, this._auth);
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> ensure(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final members = await _firestore
        .collection('members')
        .where('accountId', isEqualTo: user.uid)
        .get();
    for (final member in members.docs) {
      final memberships = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .where('memberId', isEqualTo: member.id)
          .get();
      if (memberships.docs.isEmpty) continue;
      await _firestore
          .collection('calendar_memberships')
          .doc(groupId)
          .collection('accounts')
          .doc(user.uid)
          .set({
            'memberId': member.id,
            'membershipId': memberships.docs.first.id,
          });
      return;
    }
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: '所属しないグループのカレンダーは利用できません',
    );
  }
}
