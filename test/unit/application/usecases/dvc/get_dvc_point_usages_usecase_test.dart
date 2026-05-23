import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_dvc_point_usages_usecase_test.mocks.dart';

@GenerateMocks([DvcPointUsageQueryService])
void main() {
  group('GetDvcPointUsagesUsecase', () {
    test('グループIDでDVCポイント利用が取得できること', () async {
      // Arrange
      const groupId = 'group-1';
      final expectedUsages = [
        DvcPointUsageDto(
          id: 'usage-1',
          groupId: groupId,
          usageYearMonth: DateTime(2025, 4),
          usedPoint: 100,
          memo: '春の利用',
        ),
      ];
      final queryService = MockDvcPointUsageQueryService();
      final usecase = GetDvcPointUsagesUsecase(queryService);
      when(
        queryService.getDvcPointUsagesByGroupId(
          groupId,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => expectedUsages);

      // Act
      final result = await usecase.execute(groupId);

      // Assert
      expect(result, equals(expectedUsages));
      final verification = verify(
        queryService.getDvcPointUsagesByGroupId(
          groupId,
          orderBy: captureAnyNamed('orderBy'),
        ),
      )..called(1);
      expect(
        verification.captured.single,
        equals([const OrderBy('usageYearMonth', descending: false)]),
      );
    });
  });
}
