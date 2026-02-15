import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

abstract class DvcPointUsageRepository {
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage);
  Future<void> deleteDvcPointUsage(String pointUsageId);
  Future<void> deleteDvcPointUsagesByGroupId(String groupId);
}
