import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_usage_usecase.dart';

final saveDvcPointUsageUsecaseProvider = Provider<SaveDvcPointUsageUsecase>((
  ref,
) {
  return SaveDvcPointUsageUsecase(ref.watch(dvcPointUsageRepositoryProvider));
});
