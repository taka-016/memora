import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreWriteContext {
  CollectionReference<Map<String, dynamic>> collection(String path);

  Future<QuerySnapshot<Map<String, dynamic>>> get(
    Query<Map<String, dynamic>> query,
  );

  void set(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data, [
    SetOptions? options,
  ]);

  void update(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data,
  );

  void delete(DocumentReference<Map<String, dynamic>> documentReference);

  Future<void> commit();
}

class FirestoreBatchWriteContext implements FirestoreWriteContext {
  FirestoreBatchWriteContext({required FirebaseFirestore firestore})
    : _firestore = firestore,
      _batch = firestore.batch();

  final FirebaseFirestore _firestore;
  final WriteBatch _batch;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
    Query<Map<String, dynamic>> query,
  ) {
    return query.get();
  }

  @override
  void set(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data, [
    SetOptions? options,
  ]) {
    if (options == null) {
      _batch.set(documentReference, data);
      return;
    }
    _batch.set(documentReference, data, options);
  }

  @override
  void update(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data,
  ) {
    _batch.update(documentReference, data);
  }

  @override
  void delete(DocumentReference<Map<String, dynamic>> documentReference) {
    _batch.delete(documentReference);
  }

  @override
  Future<void> commit() {
    return _batch.commit();
  }
}

class FirestoreTransactionWriteContext implements FirestoreWriteContext {
  FirestoreTransactionWriteContext({
    required FirebaseFirestore firestore,
    required Transaction transaction,
  }) : _firestore = firestore,
       _transaction = transaction;

  final FirebaseFirestore _firestore;
  final Transaction _transaction;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get(
    Query<Map<String, dynamic>> query,
  ) {
    return query.get();
  }

  @override
  void set(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data, [
    SetOptions? options,
  ]) {
    if (options == null) {
      _transaction.set(documentReference, data);
      return;
    }
    _transaction.set(documentReference, data, options);
  }

  @override
  void update(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data,
  ) {
    _transaction.update(documentReference, data);
  }

  @override
  void delete(DocumentReference<Map<String, dynamic>> documentReference) {
    _transaction.delete(documentReference);
  }

  @override
  Future<void> commit() async {}
}
