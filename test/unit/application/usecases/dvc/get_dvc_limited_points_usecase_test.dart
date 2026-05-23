import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_dvc_limited_points_usecase_test.mocks.dart';

@GenerateMocks([DvcLimitedPointQueryService])
void main() {
  group('GetDvcLimitedPointsUsecase', () {
    test('グループIDで期間限定ポイントを取得できること', () async {
      const groupId = 'group-1';
      final expectedPoints = [
        DvcLimitedPointDto(
          id: 'limited-1',
          groupId: groupId,
          startYearMonth: DateTime(2026, 1),
          endYearMonth: DateTime(2026, 3),
          point: 50,
          memo: 'キャンペーン',
        ),
      ];
      final queryService = MockDvcLimitedPointQueryService();
      final usecase = GetDvcLimitedPointsUsecase(queryService);
      when(
        queryService.getDvcLimitedPointsByGroupId(
          groupId,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => expectedPoints);

      final result = await usecase.execute(groupId);

      expect(result, equals(expectedPoints));
      final verification = verify(
        queryService.getDvcLimitedPointsByGroupId(
          groupId,
          orderBy: captureAnyNamed('orderBy'),
        ),
      )..called(1);
      expect(
        verification.captured.single,
        equals([const OrderBy('startYearMonth', descending: false)]),
      );
    });
  });
}
