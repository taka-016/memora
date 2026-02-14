import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_usage_mapper.dart';

class FirestoreDvcPointUsageRepository implements DvcPointUsageRepository {
  FirestoreDvcPointUsageRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage) async {
    await _firestore
        .collection('dvc_point_usages')
        .add(FirestoreDvcPointUsageMapper.toFirestore(pointUsage));
  }

  @override
  Future<void> deleteDvcPointUsage(String pointUsageId) async {
    await _firestore.collection('dvc_point_usages').doc(pointUsageId).delete();
  }

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {
    final snapshot = await _firestore
        .collection('dvc_point_usages')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
