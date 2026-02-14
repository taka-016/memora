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
        .add(FirestoreDvcPointContractMapper.toFirestore(contract));
  }

  @override
  Future<void> deleteDvcPointContract(String contractId) async {
    await _firestore.collection('dvc_point_contracts').doc(contractId).delete();
  }

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async {
    final snapshot = await _firestore
        .collection('dvc_point_contracts')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
