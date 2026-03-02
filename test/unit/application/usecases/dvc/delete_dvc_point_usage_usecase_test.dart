import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_point_usage_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_usage_repository.dart';

void main() {
  group('DeleteDvcPointUsageUsecase', () {
    test('利用ポイントを削除できること', () async {
      final repository = _FakeDvcPointUsageRepository();
      final usecase = DeleteDvcPointUsageUsecase(repository);

      await usecase.execute('usage-1');

      expect(repository.deletedIds, equals(['usage-1']));
    });
  });
}

class _FakeDvcPointUsageRepository implements DvcPointUsageRepository {
  final List<String> deletedIds = [];

  @override
  Future<void> deleteDvcPointUsage(String pointUsageId) async {
    deletedIds.add(pointUsageId);
  }

  @override
  Future<void> deleteDvcPointUsagesByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcPointUsage(DvcPointUsage pointUsage) async {}
}
