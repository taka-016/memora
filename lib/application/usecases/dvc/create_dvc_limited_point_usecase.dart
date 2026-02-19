import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:uuid/uuid.dart';

final createDvcLimitedPointUsecaseProvider =
    Provider<CreateDvcLimitedPointUsecase>((ref) {
      return CreateDvcLimitedPointUsecase(
        ref.watch(dvcLimitedPointRepositoryProvider),
      );
    });

class CreateDvcLimitedPointUsecase {
  CreateDvcLimitedPointUsecase(this._repository);

  final DvcLimitedPointRepository _repository;

  Future<void> execute({
    required String groupId,
    required DateTime startYearMonth,
    required DateTime endYearMonth,
    required int point,
    String? memo,
  }) async {
    final limitedPoint = DvcLimitedPoint(
      id: const Uuid().v4(),
      groupId: groupId,
      startYearMonth: DateTime(startYearMonth.year, startYearMonth.month),
      endYearMonth: DateTime(endYearMonth.year, endYearMonth.month),
      point: point,
      memo: memo,
    );

    await _repository.saveDvcLimitedPoint(limitedPoint);
  }
}
