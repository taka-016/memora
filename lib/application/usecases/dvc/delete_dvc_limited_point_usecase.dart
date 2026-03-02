import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteDvcLimitedPointUsecaseProvider =
    Provider<DeleteDvcLimitedPointUsecase>((ref) {
      return DeleteDvcLimitedPointUsecase(
        ref.watch(dvcLimitedPointRepositoryProvider),
      );
    });

class DeleteDvcLimitedPointUsecase {
  DeleteDvcLimitedPointUsecase(this._dvcLimitedPointRepository);

  final DvcLimitedPointRepository _dvcLimitedPointRepository;

  Future<void> execute(String limitedPointId) async {
    await _dvcLimitedPointRepository.deleteDvcLimitedPoint(limitedPointId);
  }
}
