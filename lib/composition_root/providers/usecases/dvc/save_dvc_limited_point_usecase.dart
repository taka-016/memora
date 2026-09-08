import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';

final saveDvcLimitedPointUsecaseProvider = Provider<SaveDvcLimitedPointUsecase>(
  (ref) {
    return SaveDvcLimitedPointUsecase(
      ref.watch(dvcLimitedPointRepositoryProvider),
    );
  },
);
