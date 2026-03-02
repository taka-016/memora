import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';

void main() {
  group('SaveDvcLimitedPointUsecase', () {
    test('期間限定ポイントを保存できること', () async {
      final repository = _FakeDvcLimitedPointRepository();
      final usecase = SaveDvcLimitedPointUsecase(repository);
      final limitedPoint = DvcLimitedPointDto(
        id: '',
        groupId: 'group-1',
        startYearMonth: DateTime(2026, 1),
        endYearMonth: DateTime(2026, 2),
        point: 30,
        memo: 'メモ',
      );

      await usecase.execute(limitedPoint);

      expect(repository.savedLimitedPoints, hasLength(1));
      expect(repository.savedLimitedPoints.first.groupId, equals('group-1'));
      expect(repository.savedLimitedPoints.first.point, equals(30));
      expect(repository.savedLimitedPoints.first.memo, equals('メモ'));
    });
  });
}

class _FakeDvcLimitedPointRepository implements DvcLimitedPointRepository {
  final List<DvcLimitedPoint> savedLimitedPoints = [];

  @override
  Future<void> deleteDvcLimitedPoint(String limitedPointId) async {}

  @override
  Future<void> deleteDvcLimitedPointsByGroupId(String groupId) async {}

  @override
  Future<void> saveDvcLimitedPoint(DvcLimitedPoint limitedPoint) async {
    savedLimitedPoints.add(limitedPoint);
  }
}
