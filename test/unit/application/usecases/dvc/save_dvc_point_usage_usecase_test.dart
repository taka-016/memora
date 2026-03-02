import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_usage_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';

void main() {
  group('SaveDvcPointUsageUsecase', () {
    test('利用ポイントを保存できること', () async {
      final repository = _FakeDvcPointUsageRepository();
      final usecase = SaveDvcPointUsageUsecase(repository);
      final usage = DvcPointUsageDto(
        id: '',
        groupId: 'group-1',
        usageYearMonth: DateTime(2026, 1),
        usedPoint: 25,
        memo: 'レストラン',
      );

      await usecase.execute(usage);

      expect(repository.savedUsages, hasLength(1));
      expect(repository.savedUsages.first.groupId, equals('group-1'));
      expect(repository.savedUsages.first.usedPoint, equals(25));
      expect(repository.savedUsages.first.memo, equals('レストラン'));
    });
  });
}

class _FakeDvcPointUsageRepository implements DvcPointUsageRepository {
  final List<DvcPointUsage> savedUsages = [];

  @override
  Future<void> deleteDvcPointUsage(String pointUsageId) async {}

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage) async {
    savedUsages.add(pointUsage);
  }
}
