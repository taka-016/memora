import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_usage_mapper.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';

class SaveDvcPointUsageUsecase {
  SaveDvcPointUsageUsecase(this._dvcPointUsageRepository);

  final DvcPointUsageRepository _dvcPointUsageRepository;

  Future<void> execute(DvcPointUsageDto usage) async {
    await _dvcPointUsageRepository.saveDvcPointUsage(
      DvcPointUsageMapper.toEntity(usage),
    );
  }
}
