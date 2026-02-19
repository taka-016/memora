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
  GetDvcPointUsagesUsecase(this._queryService);

  final DvcPointUsageQueryService _queryService;

  Future<List<DvcPointUsageDto>> execute(String groupId) async {
    return _queryService.getDvcPointUsagesByGroupId(
      groupId,
      orderBy: const [OrderBy('usageYearMonth', descending: false)],
    );
  }
}
