import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

abstract class DvcLimitedPointRepository {
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint limitedPoint);
  Future<void> deleteDvcLimitedPoint(String limitedPointId);
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId);
}
