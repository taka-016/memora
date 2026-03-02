import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_limited_point_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';

void main() {
  group('DeleteDvcLimitedPointUsecase', () {
    test('期間限定ポイントを削除できること', () async {
      final repository = _FakeDvcLimitedPointRepository();
      final usecase = DeleteDvcLimitedPointUsecase(repository);

      await usecase.execute('limited-1');

      expect(repository.deletedIds, equals(['limited-1']));
    });
  });
}

class _FakeDvcLimitedPointRepository implements DvcLimitedPointRepository {
  final List<String> deletedIds = [];

  @override
  Future<void> deleteDvcLimitedPoint(String limitedPointId) async {
    deletedIds.add(limitedPointId);
  }

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint limitedPoint) async {}
}
