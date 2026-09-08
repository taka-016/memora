import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';

final getDvcLimitedPointsUsecaseProvider = Provider<GetDvcLimitedPointsUsecase>(
  (ref) {
    return GetDvcLimitedPointsUsecase(
      ref.watch(dvcLimitedPointQueryServiceProvider),
    );
  },
);
