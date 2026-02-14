import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';

void main() {
  group('DvcLimitedPointDto', () {
    test('必須パラメータで生成できる', () {
      final dto = DvcLimitedPointDto(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
      );

      expect(dto.id, 'limited001');
      expect(dto.groupId, 'group001');
      expect(dto.startYearMonth, DateTime(2025, 7));
      expect(dto.endYearMonth, DateTime(2025, 12));
      expect(dto.point, 30);
      expect(dto.memo, isNull);
    });

    test('copyWithで値を更新できる', () {
      final dto = DvcLimitedPointDto(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
      );

      final copied = dto.copyWith(point: 40, memo: '追加付与');

      expect(copied.point, 40);
      expect(copied.memo, '追加付与');
      expect(copied.groupId, 'group001');
    });
  });
}
