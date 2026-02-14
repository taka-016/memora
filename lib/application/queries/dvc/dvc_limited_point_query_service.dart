import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class DvcLimitedPointQueryService {
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  });
}
