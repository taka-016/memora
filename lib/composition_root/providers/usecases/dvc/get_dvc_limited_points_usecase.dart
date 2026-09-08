import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';

final getDvcLimitedPointsUsecaseProvider = Provider<GetDvcLimitedPointsUsecase>(
  (ref) {
    return GetDvcLimitedPointsUsecase(
      ref.watch(dvcLimitedPointQueryServiceProvider),
    );
  },
);
