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
    await _firestore
        .collection('dvc_point_contracts')
        .doc(contract.id.isEmpty ? null : contract.id)
        .set(
          (contract.version == null
              ? FirestoreDvcPointContractMapper.toCreateFirestore(contract)
              : FirestoreDvcPointContractMapper.toUpdateFirestore(contract)),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> saveDvcPointContracts(
    String groupId,
    List<DvcPointContract> contracts,
  ) async {
    final collection = _firestore.collection('dvc_point_contracts');
    final existing = await collection
        .where('groupId', isEqualTo: groupId)
        .get();
    final existingIds = existing.docs.map((v) => v.id).toSet();
    final retainedIds = contracts.map((v) => v.id).toSet();
    final deleted = existing.docs
        .where((v) => !retainedIds.contains(v.id))
        .toList();
    for (final doc in deleted) {
      await _ensureDeletable(doc.id);
    }
    final batch = _firestore.batch();
    for (final doc in deleted) {
      batch.delete(doc.reference);
    }
    for (final contract in contracts) {
      if (existingIds.contains(contract.id)) {
        final data = FirestoreDvcPointContractMapper.toUpdateFirestore(
          contract,
        );
        batch.update(collection.doc(contract.id), data);
      } else {
        batch.set(
          collection.doc(contract.id.isEmpty ? null : contract.id),
          FirestoreDvcPointContractMapper.toCreateFirestore(contract),
        );
      }
    }
    await batch.commit();
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
    await _firestore.collection('dvc_point_contracts').doc(contractId).delete();
  }

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) =>
      saveDvcPointContracts(groupId, []);
}
