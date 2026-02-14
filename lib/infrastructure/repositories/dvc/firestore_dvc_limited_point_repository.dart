import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_limited_point_mapper.dart';

class FirestoreDvcLimitedPointRepository implements DvcLimitedPointRepository {
  FirestoreDvcLimitedPointRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint limitedPoint) async {
    await _firestore
        .collection('dvc_limited_points')
        .add(FirestoreDvcLimitedPointMapper.toFirestore(limitedPoint));
  }

  @override
  Future<void> deleteDvcLimitedPoint(String limitedPointId) async {
    await _firestore
        .collection('dvc_limited_points')
        .doc(limitedPointId)
        .delete();
  }

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async {
    final snapshot = await _firestore
        .collection('dvc_limited_points')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
