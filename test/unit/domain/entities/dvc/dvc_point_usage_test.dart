import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_usage.dart';

void main() {
  group('DvcPointUsage', () {
    test('必須パラメータでインスタンス化できる', () {
      final usage = DvcPointUsage(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
      );

      expect(usage.id, 'usage001');
      expect(usage.groupId, 'group001');
      expect(usage.usageYearMonth, DateTime(2025, 10));
      expect(usage.usedPoint, 60);
      expect(usage.memo, isNull);
    });

    test('copyWithで値を更新できる', () {
      final usage = DvcPointUsage(
        id: 'usage001',
        groupId: 'group001',
        usageYearMonth: DateTime(2025, 10),
        usedPoint: 60,
      );

      final copied = usage.copyWith(usedPoint: 80, memo: 'バケーション用');

      expect(copied.usedPoint, 80);
      expect(copied.memo, 'バケーション用');
      expect(copied.groupId, 'group001');
    });
  });
}
