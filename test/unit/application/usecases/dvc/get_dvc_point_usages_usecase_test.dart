import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/domain/value_objects/order_by.dart';

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
      final queryService = _FakeDvcPointUsageQueryService(expectedUsages);
      final usecase = GetDvcPointUsagesUsecase(queryService);

      // Act
      final result = await usecase.execute(groupId);

      // Assert
      expect(result, equals(expectedUsages));
      expect(queryService.receivedGroupId, equals(groupId));
      expect(
        queryService.receivedOrderBy,
        equals([const OrderBy('usageYearMonth', descending: false)]),
      );
    });
  });
}

class _FakeDvcPointUsageQueryService implements DvcPointUsageQueryService {
  _FakeDvcPointUsageQueryService(this._usages);

  final List<DvcPointUsageDto> _usages;
  String? receivedGroupId;
  List<OrderBy>? receivedOrderBy;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    receivedGroupId = groupId;
    receivedOrderBy = orderBy;
    return _usages;
  }
}
