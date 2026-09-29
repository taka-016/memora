import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';

class DeleteDvcLimitedPointUsecase {
  DeleteDvcLimitedPointUsecase(this._dvcLimitedPointRepository);

  final DvcLimitedPointRepository _dvcLimitedPointRepository;

  Future<void> execute(String limitedPointId) async {
    await _dvcLimitedPointRepository.deleteDvcLimitedPoint(limitedPointId);
  }
}
