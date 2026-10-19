import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

abstract class DvcPointUsageRepository {
  Future<void> saveDvcPointUsage(
    DvcPointUsage pointUsage, {
    int? expectedContractVersion,
  });
  Future<void> deleteDvcPointUsage(
    String pointUsageId, {
    int? expectedContractVersion,
  });
  Future<void> deleteDvcPointUsagesByGroupId(String groupId);
}
