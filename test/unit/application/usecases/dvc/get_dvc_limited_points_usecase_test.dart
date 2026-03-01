import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/usecases/dvc/get_dvc_limited_points_usecase.dart';
import 'package:memora/domain/value_objects/order_by.dart';

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
      final queryService = _FakeDvcLimitedPointQueryService(expectedPoints);
      final usecase = GetDvcLimitedPointsUsecase(queryService);

      final result = await usecase.execute(groupId);

      expect(result, equals(expectedPoints));
      expect(queryService.receivedGroupId, equals(groupId));
      expect(
        queryService.receivedOrderBy,
        equals([const OrderBy('startYearMonth', descending: false)]),
      );
    });
  });
}

class _FakeDvcLimitedPointQueryService implements DvcLimitedPointQueryService {
  _FakeDvcLimitedPointQueryService(this._points);

  final List<DvcLimitedPointDto> _points;
  String? receivedGroupId;
  List<OrderBy>? receivedOrderBy;

  @override
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    receivedGroupId = groupId;
    receivedOrderBy = orderBy;
    return _points;
  }
}
