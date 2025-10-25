import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/pin_detail.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('PinDetail', () {
    test('インスタンス生成が正しく行われる', () {
      final detail = PinDetail(
        pinId: 'pin001',
        name: 'エッフェル塔観光',
        startDate: DateTime(2025, 6, 2, 9, 0),
        endDate: DateTime(2025, 6, 2, 12, 0),
        memo: '午前中に観光',
      );

      expect(detail.pinId, 'pin001');
      expect(detail.name, 'エッフェル塔観光');
      expect(detail.startDate, DateTime(2025, 6, 2, 9, 0));
      expect(detail.endDate, DateTime(2025, 6, 2, 12, 0));
      expect(detail.memo, '午前中に観光');
    });

    test('詳細終了日時が開始日時より前の場合はArgumentErrorが発生する', () {
      expect(
        () => PinDetail(
          pinId: 'pin001',
          startDate: DateTime(2025, 6, 2, 12, 0),
          endDate: DateTime(2025, 6, 2, 9, 0),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final detail = PinDetail(pinId: 'pin001');

      expect(detail.name, null);
      expect(detail.startDate, null);
      expect(detail.endDate, null);
      expect(detail.memo, null);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final detail1 = PinDetail(pinId: 'pin001');
      final detail2 = PinDetail(pinId: 'pin001');

      expect(detail1, equals(detail2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final detail = PinDetail(pinId: 'pin001');

      final updated = detail.copyWith(
        name: 'ルーヴル美術館',
        memo: '夕方に訪問',
        startDate: DateTime(2025, 6, 2, 16, 0),
        endDate: DateTime(2025, 6, 2, 19, 0),
      );

      expect(updated.name, 'ルーヴル美術館');
      expect(updated.memo, '夕方に訪問');
      expect(updated.startDate, DateTime(2025, 6, 2, 16, 0));
      expect(updated.endDate, DateTime(2025, 6, 2, 19, 0));
    });
  });
}
