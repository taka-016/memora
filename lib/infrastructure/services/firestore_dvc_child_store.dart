import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';
import 'package:memora/infrastructure/services/firestore_version_check.dart';

class FirestoreDvcChildStore {
  FirestoreDvcChildStore(this._firestore, this._collection);

  final FirebaseFirestore _firestore;
  final String _collection;

  DocumentReference<Map<String, dynamic>> _contract(String id) =>
      _firestore.collection('dvc_point_contracts').doc(id);

  Map<String, dynamic> _nextVersion(int? expectedVersion) => {
    'version': expectedVersion == null ? null : expectedVersion + 1,
    ...FirestoreWriteMetadata.forUpdate(),
  };

  Future<void> save(
    String id,
    String contractId,
    Map<String, dynamic> data,
    int? expectedVersion,
  ) async {
    final batch = _firestore.batch();
    batch.update(_contract(contractId), _nextVersion(expectedVersion));
    batch.set(
      _firestore.collection(_collection).doc(id.isEmpty ? null : id),
      data,
    );
    await batch.commit();
  }

  Future<void> delete(String id, int? expectedVersion) async {
    final child = _firestore.collection(_collection).doc(id);
    await _firestore.runTransaction<void>((transaction) async {
      final childSnapshot = await transaction.get(child);
      final contract = _contract(childSnapshot.data()!['contractId'] as String);
      final parent = await transaction.get(contract);
      FirestoreVersionCheck.requireMatch(parent.data(), expectedVersion);
      transaction.update(contract, _nextVersion(expectedVersion));
      transaction.delete(child);
    });
  }

  Future<void> deleteByGroupId(String groupId) async {
    final children = await _firestore
        .collection(_collection)
        .where('groupId', isEqualTo: groupId)
        .get();
    final contractIds = children.docs
        .map((child) => child.data()['contractId'] as String)
        .toSet();
    final expected = <String, int?>{};
    await _firestore.runTransaction<void>((transaction) async {
      for (final id in contractIds) {
        final parent = await transaction.get(_contract(id));
        final version = expected.putIfAbsent(
          id,
          () => parent.data()?['version'] as int?,
        );
        FirestoreVersionCheck.requireMatch(parent.data(), version);
      }
      for (final entry in expected.entries) {
        transaction.update(_contract(entry.key), _nextVersion(entry.value));
      }
      for (final child in children.docs) {
        transaction.delete(child.reference);
      }
    });
  }
}
