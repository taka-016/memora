import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_point_usage_usecase.dart';

final deleteDvcPointUsageUsecaseProvider = Provider<DeleteDvcPointUsageUsecase>(
  (ref) {
    return DeleteDvcPointUsageUsecase(
      ref.watch(dvcPointUsageRepositoryProvider),
    );
  },
);
