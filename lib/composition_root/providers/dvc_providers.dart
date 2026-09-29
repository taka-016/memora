import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_point_usage_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_contracts_usecase.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_usage_usecase.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteDvcLimitedPointUsecaseProvider =
    Provider<DeleteDvcLimitedPointUsecase>((ref) {
      return DeleteDvcLimitedPointUsecase(
        ref.watch(dvcLimitedPointRepositoryProvider),
      );
    });

final deleteDvcPointUsageUsecaseProvider = Provider<DeleteDvcPointUsageUsecase>(
  (ref) {
    return DeleteDvcPointUsageUsecase(
      ref.watch(dvcPointUsageRepositoryProvider),
    );
  },
);

final getDvcLimitedPointsUsecaseProvider = Provider<GetDvcLimitedPointsUsecase>(
  (ref) {
    return GetDvcLimitedPointsUsecase(
      ref.watch(dvcLimitedPointQueryServiceProvider),
    );
  },
);

final getDvcPointContractsUsecaseProvider =
    Provider<GetDvcPointContractsUsecase>((ref) {
      return GetDvcPointContractsUsecase(
        ref.watch(dvcPointContractQueryServiceProvider),
      );
    });

final getDvcPointUsagesUsecaseProvider = Provider<GetDvcPointUsagesUsecase>((
  ref,
) {
  return GetDvcPointUsagesUsecase(ref.watch(dvcPointUsageQueryServiceProvider));
});

final saveDvcLimitedPointUsecaseProvider = Provider<SaveDvcLimitedPointUsecase>(
  (ref) {
    return SaveDvcLimitedPointUsecase(
      ref.watch(dvcLimitedPointRepositoryProvider),
    );
  },
);

final saveDvcPointContractsUsecaseProvider =
    Provider<SaveDvcPointContractsUsecase>((ref) {
      return SaveDvcPointContractsUsecase(
        ref.watch(dvcPointContractRepositoryProvider),
      );
    });

final saveDvcPointUsageUsecaseProvider = Provider<SaveDvcPointUsageUsecase>((
  ref,
) {
  return SaveDvcPointUsageUsecase(ref.watch(dvcPointUsageRepositoryProvider));
});
