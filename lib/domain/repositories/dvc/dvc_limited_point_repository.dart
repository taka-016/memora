import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

abstract class DvcLimitedPointRepository {
  Future<void> saveDvcLimitedPoint(
    DvcLimitedPoint limitedPoint, {
    int? expectedContractVersion,
  });
  Future<void> deleteDvcLimitedPoint(
    String limitedPointId, {
    int? expectedContractVersion,
  });
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId);
}
