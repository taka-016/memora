import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getDvcLimitedPointsUsecaseProvider = Provider<GetDvcLimitedPointsUsecase>(
  (ref) {
    return GetDvcLimitedPointsUsecase(
      ref.watch(dvcLimitedPointQueryServiceProvider),
    );
  },
);

class GetDvcLimitedPointsUsecase {
  GetDvcLimitedPointsUsecase(this._queryService);

  final DvcLimitedPointQueryService _queryService;

  Future<List<DvcLimitedPointDto>> execute(String groupId) async {
    return _queryService.getDvcLimitedPointsByGroupId(
      groupId,
      orderBy: const [OrderBy('startYearMonth', descending: false)],
    );
  }
}
