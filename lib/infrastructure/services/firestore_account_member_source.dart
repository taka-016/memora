import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreAccountMemberSource {
  FirestoreAccountMemberSource(this._firestore, {String? Function()? accountId})
    : _accountId = accountId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore _firestore;
  final String? Function() _accountId;

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> current() async {
    final id = _accountId();
    return id == null ? null : forAccount(id);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> forAccount(
    String accountId,
  ) async {
    final snapshot = await _firestore
        .collection('members')
        .where('accountId', isEqualTo: accountId)
        .limit(1)
        .get();
    return snapshot.docs.firstOrNull;
  }
}
