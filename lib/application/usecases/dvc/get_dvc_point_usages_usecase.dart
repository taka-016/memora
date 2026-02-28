import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getDvcPointUsagesUsecaseProvider = Provider<GetDvcPointUsagesUsecase>((
  ref,
) {
  return GetDvcPointUsagesUsecase(ref.watch(dvcPointUsageQueryServiceProvider));
});

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
