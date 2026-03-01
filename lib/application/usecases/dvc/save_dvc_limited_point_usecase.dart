import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_limited_point_mapper.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveDvcLimitedPointUsecaseProvider = Provider<SaveDvcLimitedPointUsecase>(
  (ref) {
    return SaveDvcLimitedPointUsecase(
      ref.watch(dvcLimitedPointRepositoryProvider),
    );
  },
);

class SaveDvcLimitedPointUsecase {
  SaveDvcLimitedPointUsecase(this._dvcLimitedPointRepository);

  final DvcLimitedPointRepository _dvcLimitedPointRepository;

  Future<void> execute(DvcLimitedPointDto limitedPoint) async {
    await _dvcLimitedPointRepository.saveDvcLimitedPoint(
      DvcLimitedPointMapper.toEntity(limitedPoint),
    );
  }
}
