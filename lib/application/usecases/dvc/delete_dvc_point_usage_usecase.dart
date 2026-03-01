import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteDvcPointUsageUsecaseProvider = Provider<DeleteDvcPointUsageUsecase>(
  (ref) {
    return DeleteDvcPointUsageUsecase(
      ref.watch(dvcPointUsageRepositoryProvider),
    );
  },
);

class DeleteDvcPointUsageUsecase {
  DeleteDvcPointUsageUsecase(this._dvcPointUsageRepository);

  final DvcPointUsageRepository _dvcPointUsageRepository;

  Future<void> execute(String pointUsageId) async {
    await _dvcPointUsageRepository.deleteDvcPointUsage(pointUsageId);
  }
}
