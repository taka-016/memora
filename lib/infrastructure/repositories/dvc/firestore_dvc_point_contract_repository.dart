import 'package:memora/infrastructure/services/firestore_version_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_contract_mapper.dart';

class FirestoreDvcPointContractRepository
    implements DvcPointContractRepository {
  FirestoreDvcPointContractRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveDvcPointContract(DvcPointContract contract) async {
    final reference = _firestore
        .collection('dvc_point_contracts')
        .doc(contract.id.isEmpty ? null : contract.id);
    final batch = _firestore.batch();
    if (contract.version == null) {
      batch.set(
        reference,
        FirestoreDvcPointContractMapper.toCreateFirestore(contract),
      );
    } else {
      batch.update(
        reference,
        FirestoreDvcPointContractMapper.toUpdateFirestore(contract),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> saveDvcPointContracts(
    String groupId,
    List<DvcPointContract> contracts, {
    Map<String, int> expectedVersions = const {},
  }) async {
    final collection = _firestore.collection('dvc_point_contracts');
    final existing = await collection
        .where('groupId', isEqualTo: groupId)
        .get();
    final retainedIds = contracts.map((v) => v.id).toSet();
    final deleted = existing.docs
        .where((v) => !retainedIds.contains(v.id))
        .toList();
    for (final doc in deleted) {
      await _ensureDeletable(doc.id);
    }
    await _firestore.runTransaction<void>((transaction) async {
      for (final doc in deleted) {
        final current = await transaction.get(doc.reference);
        FirestoreVersionCheck.requireMatch(
          current.data(),
          expectedVersions[doc.id],
        );
      }
      for (final doc in deleted) {
        transaction.delete(doc.reference);
      }
      for (final contract in contracts) {
        final reference = collection.doc(
          contract.id.isEmpty ? null : contract.id,
        );
        if (contract.version == null) {
          transaction.set(
            reference,
            FirestoreDvcPointContractMapper.toCreateFirestore(contract),
          );
        } else {
          transaction.update(
            reference,
            FirestoreDvcPointContractMapper.toUpdateFirestore(contract),
          );
        }
      }
    });
  }

  Future<void> _ensureDeletable(String contractId) async {
    for (final name in ['dvc_point_usages', 'dvc_limited_points']) {
      final children = await _firestore
          .collection(name)
          .where('contractId', isEqualTo: contractId)
          .limit(1)
          .get();
      if (children.docs.isNotEmpty) {
        throw StateError('利用履歴・期間限定ポイントがある契約は削除できません');
      }
    }
  }

  @override
  Future<void> deleteDvcPointContract(
    String contractId, {
    int? expectedVersion,
  }) async {
    await _ensureDeletable(contractId);
    await FirestoreVersionCheck.delete(
      _firestore,
      _firestore.collection('dvc_point_contracts').doc(contractId),
      expectedVersion,
    );
  }

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async {
    final snapshot = await _firestore
        .collection('dvc_point_contracts')
        .where('groupId', isEqualTo: groupId)
        .get();
    await saveDvcPointContracts(
      groupId,
      [],
      expectedVersions: {
        for (final doc in snapshot.docs) doc.id: doc.data()['version'] as int,
      },
    );
  }
}
