import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';

void main() {
  group('DvcPointUsageDto', () {
    test('必須パラメータで生成できる', () {
      final dto = DvcPointUsageDto(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
      );

      expect(dto.id, 'usage001');
      expect(dto.groupId, 'group001');
      expect(dto.usageYearMonth, DateTime(2025, 10));
      expect(dto.usedPoint, 60);
      expect(dto.memo, isNull);
    });

    test('copyWithで値を更新できる', () {
      final dto = DvcPointUsageDto(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
      );

      final copied = dto.copyWith(usedPoint: 80, memo: 'メモ更新');

      expect(copied.usedPoint, 80);
      expect(copied.memo, 'メモ更新');
      expect(copied.groupId, 'group001');
    });
  });
}
