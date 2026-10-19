import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_limited_point_mapper.dart';
import 'package:memora/infrastructure/services/firestore_dvc_child_store.dart';

class FirestoreDvcLimitedPointRepository implements DvcLimitedPointRepository {
  FirestoreDvcLimitedPointRepository({FirebaseFirestore? firestore})
    : _store = FirestoreDvcChildStore(
        firestore ?? FirebaseFirestore.instance,
        'dvc_limited_points',
      );

  final FirestoreDvcChildStore _store;

  @override
  Future<void> saveDvcLimitedPoint(
    DvcLimitedPoint value, {
    int? expectedContractVersion,
  }) => _store.save(
    value.id,
    value.contractId,
    FirestoreDvcLimitedPointMapper.toCreateFirestore(value),
    expectedContractVersion,
  );

  @override
  Future<void> deleteDvcLimitedPoint(
    String id, {
    int? expectedContractVersion,
  }) => _store.delete(id, expectedContractVersion);

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) =>
      _store.deleteByGroupId(groupId);
}
