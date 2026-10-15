import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

class GetDvcLimitedPointsUsecase {
  GetDvcLimitedPointsUsecase(this._dvcLimitedPointQueryService);

  final DvcLimitedPointQueryService _dvcLimitedPointQueryService;

  Future<List<DvcLimitedPointDto>> execute(
    String groupId, {
    String? contractId,
  }) async {
    return _dvcLimitedPointQueryService.getDvcLimitedPointsByGroupId(
      groupId,
      contractId: contractId,
      orderBy: [const OrderBy('startYearMonth', descending: false)],
    );
  }
}
