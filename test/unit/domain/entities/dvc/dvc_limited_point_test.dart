import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_limited_point.dart';

void main() {
  group('DvcLimitedPoint', () {
    test('必須パラメータでインスタンス化できる', () {
      final point = DvcLimitedPoint(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
      );

      expect(point.id, 'limited001');
      expect(point.groupId, 'group001');
      expect(point.startYearMonth, DateTime(2025, 7));
      expect(point.endYearMonth, DateTime(2025, 12));
      expect(point.point, 30);
      expect(point.memo, isNull);
    });

    test('copyWithで値を更新できる', () {
      final point = DvcLimitedPoint(
        id: 'limited001',
        groupId: 'group001',
        startYearMonth: DateTime(2025, 7),
        endYearMonth: DateTime(2025, 12),
        point: 30,
      );

      final copied = point.copyWith(point: 40, memo: 'ワンタイムユース');

      expect(copied.point, 40);
      expect(copied.memo, 'ワンタイムユース');
      expect(copied.groupId, 'group001');
    });
  });
}
