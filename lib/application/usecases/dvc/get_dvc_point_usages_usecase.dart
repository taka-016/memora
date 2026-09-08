import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

class GetDvcPointUsagesUsecase {
  final DvcPointUsageQueryService _dvcPointUsageQueryService;

  GetDvcPointUsagesUsecase(this._dvcPointUsageQueryService);

  Future<List<DvcPointUsageDto>> execute(String groupId) async {
    return await _dvcPointUsageQueryService.getDvcPointUsagesByGroupId(
      groupId,
      orderBy: [const OrderBy('usageYearMonth', descending: false)],
    );
  }
}
