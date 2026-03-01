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
  GetDvcLimitedPointsUsecase(this._dvcLimitedPointQueryService);

  final DvcLimitedPointQueryService _dvcLimitedPointQueryService;

  Future<List<DvcLimitedPointDto>> execute(String groupId) async {
    return _dvcLimitedPointQueryService.getDvcLimitedPointsByGroupId(
      groupId,
      orderBy: [const OrderBy('startYearMonth', descending: false)],
    );
  }
}
