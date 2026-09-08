import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';

final saveDvcLimitedPointUsecaseProvider = Provider<SaveDvcLimitedPointUsecase>(
  (ref) {
    return SaveDvcLimitedPointUsecase(
      ref.watch(dvcLimitedPointRepositoryProvider),
    );
  },
);
