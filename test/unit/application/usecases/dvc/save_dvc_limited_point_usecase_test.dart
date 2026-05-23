import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/usecases/dvc/save_dvc_limited_point_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';
import 'package:memora/domain/repositories/dvc/dvc_limited_point_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'save_dvc_limited_point_usecase_test.mocks.dart';

@GenerateMocks([DvcLimitedPointRepository])
void main() {
  group('SaveDvcLimitedPointUsecase', () {
    test('期間限定ポイントを保存できること', () async {
      final repository = MockDvcLimitedPointRepository();
      final usecase = SaveDvcLimitedPointUsecase(repository);
      final limitedPoint = DvcLimitedPointDto(
        id: '',
        groupId: 'group-1',
        startYearMonth: DateTime(2026, 1),
        endYearMonth: DateTime(2026, 2),
        point: 30,
        memo: 'メモ',
      );
      when(repository.saveDvcLimitedPoint(any)).thenAnswer((_) async {});

      await usecase.execute(limitedPoint);

      final verification = verify(repository.saveDvcLimitedPoint(captureAny))
        ..called(1);
      final savedLimitedPoint = verification.captured.single as DvcLimitedPoint;
      expect(savedLimitedPoint.groupId, equals('group-1'));
      expect(savedLimitedPoint.point, equals(30));
      expect(savedLimitedPoint.memo, equals('メモ'));
    });
  });
}
