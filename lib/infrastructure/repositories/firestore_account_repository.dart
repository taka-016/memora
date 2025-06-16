import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/entities/account.dart';
import '../mappers/firestore_account_mapper.dart';

class FirestoreAccountRepository implements AccountRepository {
  final FirebaseFirestore _firestore;

  FirestoreAccountRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveAccount(Account account) async {
    await _firestore.collection('accounts').add(
      FirestoreAccountMapper.toFirestore(account),
    );
  }

  @override
  Future<List<Account>> getAccounts() async {
    try {
      final snapshot = await _firestore.collection('accounts').get();
      return snapshot.docs
          .map((doc) => FirestoreAccountMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _firestore.collection('accounts').doc(accountId).delete();
  }

  @override
  Future<Account?> getAccountById(String accountId) async {
    try {
      final doc = await _firestore.collection('accounts').doc(accountId).get();
      if (doc.exists) {
        return FirestoreAccountMapper.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Account?> getAccountByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('accounts')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return FirestoreAccountMapper.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}