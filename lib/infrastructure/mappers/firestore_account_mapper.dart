import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/account.dart';

class FirestoreAccountMapper {
  static Account fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Account(
      id: doc.id,
      email: data?['email'] as String? ?? '',
      password: data?['password'] as String? ?? '',
      name: data?['name'] as String? ?? '',
      memberId: data?['memberId'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(Account account) {
    return {
      'email': account.email,
      'password': account.password,
      'name': account.name,
      'memberId': account.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}