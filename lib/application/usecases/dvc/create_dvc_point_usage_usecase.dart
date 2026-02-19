import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:uuid/uuid.dart';

final createDvcPointUsageUsecaseProvider = Provider<CreateDvcPointUsageUsecase>(
  (ref) {
    return CreateDvcPointUsageUsecase(
      ref.watch(dvcPointUsageRepositoryProvider),
    );
  },
);

class CreateDvcPointUsageUsecase {
  CreateDvcPointUsageUsecase(this._repository);

  final DvcPointUsageRepository _repository;

  Future<void> execute({
    required String groupId,
    required DateTime usageYearMonth,
    required int usedPoint,
    String? memo,
  }) async {
    final usage = DvcPointUsage(
      id: const Uuid().v4(),
      groupId: groupId,
      usageYearMonth: DateTime(usageYearMonth.year, usageYearMonth.month),
      usedPoint: usedPoint,
      memo: memo,
    );

    await _repository.saveDvcPointUsage(usage);
  }
}
