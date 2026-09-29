import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';

class DeleteDvcPointUsageUsecase {
  DeleteDvcPointUsageUsecase(this._dvcPointUsageRepository);

  final DvcPointUsageRepository _dvcPointUsageRepository;

  Future<void> execute(String pointUsageId) async {
    await _dvcPointUsageRepository.deleteDvcPointUsage(pointUsageId);
  }
}
