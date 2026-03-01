import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_usage_mapper.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveDvcPointUsageUsecaseProvider = Provider<SaveDvcPointUsageUsecase>((
  ref,
) {
  return SaveDvcPointUsageUsecase(ref.watch(dvcPointUsageRepositoryProvider));
});

class SaveDvcPointUsageUsecase {
  SaveDvcPointUsageUsecase(this._dvcPointUsageRepository);

  final DvcPointUsageRepository _dvcPointUsageRepository;

  Future<void> execute(DvcPointUsageDto usage) async {
    await _dvcPointUsageRepository.saveDvcPointUsage(
      DvcPointUsageMapper.toEntity(usage),
    );
  }
}
