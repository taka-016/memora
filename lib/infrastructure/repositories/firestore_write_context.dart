import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestoreWriteContext {
  CollectionReference<Map<String, dynamic>> collection(String path);

  Future<QuerySnapshot<Map<String, dynamic>>> get(
    Query<Map<String, dynamic>> query,
  );

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> reference,
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
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) => reference.get();

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
    required this._firestore,
    required this._transaction,
  });

  final FirebaseFirestore _firestore;
  final Transaction _transaction;
  final _writes = <void Function()>[];

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
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) => _transaction.get(reference);

  @override
  void set(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data, [
    SetOptions? options,
  ]) {
    if (options == null) {
      _writes.add(() => _transaction.set(documentReference, data));
      return;
    }
    _writes.add(() => _transaction.set(documentReference, data, options));
  }

  @override
  void update(
    DocumentReference<Map<String, dynamic>> documentReference,
    Map<String, dynamic> data,
  ) {
    _writes.add(() => _transaction.update(documentReference, data));
  }

  @override
  void delete(DocumentReference<Map<String, dynamic>> documentReference) {
    _writes.add(() => _transaction.delete(documentReference));
  }

  @override
  Future<void> commit() async {
    for (final write in _writes) {
      write();
    }
    _writes.clear();
  }
}
