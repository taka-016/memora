import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_usage_mapper.dart';
import 'package:memora/infrastructure/services/firestore_dvc_child_store.dart';

class FirestoreDvcPointUsageRepository implements DvcPointUsageRepository {
  FirestoreDvcPointUsageRepository({FirebaseFirestore? firestore})
    : _store = FirestoreDvcChildStore(
        firestore ?? FirebaseFirestore.instance,
        'dvc_point_usages',
      );

  final FirestoreDvcChildStore _store;

  @override
  Future<void> saveDvcPointUsage(
    DvcPointUsage value, {
    int? expectedContractVersion,
  }) => _store.save(
    value.id,
    value.contractId,
    FirestoreDvcPointUsageMapper.toCreateFirestore(value),
    expectedContractVersion,
  );

  @override
  Future<void> deleteDvcPointUsage(String id, {int? expectedContractVersion}) =>
      _store.delete(id, expectedContractVersion);

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) =>
      _store.deleteByGroupId(groupId);
}
