import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreAccountPermissions {
  FirestoreAccountPermissions(Map<String, dynamic> data)
    : memberId = data['memberId'] as String,
      memberGroupIds = List<String>.unmodifiable(
        data['memberGroupIds'] as List,
      ),
      managedGroupIds = List<String>.unmodifiable(
        data['managedGroupIds'] as List,
      );

  final String memberId;
  final List<String> memberGroupIds;
  final List<String> managedGroupIds;
}

class FirestoreAccountPermissionsSource {
  FirestoreAccountPermissionsSource(
    this.firestore, {
    String? Function()? accountId,
  }) : _accountId = accountId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore firestore;
  final String? Function() _accountId;

  Future<FirestoreAccountPermissions?> current() async {
    final id = _accountId();
    if (id == null) return null;
    return forAccount(id);
  }

  Future<FirestoreAccountPermissions?> forAccount(String accountId) async {
    final doc = await firestore
        .collection('account_permissions')
        .doc(accountId)
        .get();
    return doc.exists ? FirestoreAccountPermissions(doc.data()!) : null;
  }
}
