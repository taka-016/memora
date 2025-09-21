import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/pin_detail.dart';

void main() {
  group('PinDetail', () {
    test('インスタンス生成が正しく行われる', () {
      final detail = PinDetail(
        id: 'detail001',
        detailId: 'detail001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
        detailName: 'エッフェル塔観光',
        detailStartDate: DateTime(2025, 6, 2, 9, 0),
        detailEndDate: DateTime(2025, 6, 2, 12, 0),
        detailMemo: '午前中に観光',
      );

      expect(detail.id, 'detail001');
      expect(detail.detailId, 'detail001');
      expect(detail.pinId, 'pin001');
      expect(detail.tripId, 'trip001');
      expect(detail.groupId, 'group001');
      expect(detail.detailName, 'エッフェル塔観光');
      expect(detail.detailStartDate, DateTime(2025, 6, 2, 9, 0));
      expect(detail.detailEndDate, DateTime(2025, 6, 2, 12, 0));
      expect(detail.detailMemo, '午前中に観光');
    });

    test('詳細終了日時が開始日時より前の場合はassertが発生する', () {
      expect(
        () => PinDetail(
          id: 'detail001',
          detailId: 'detail001',
          pinId: 'pin001',
          tripId: 'trip001',
          groupId: 'group001',
          detailStartDate: DateTime(2025, 6, 2, 12, 0),
          detailEndDate: DateTime(2025, 6, 2, 9, 0),
        ),
        throwsAssertionError,
      );
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final detail = PinDetail(
        id: 'detail001',
        detailId: 'detail001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
      );

      expect(detail.detailName, null);
      expect(detail.detailStartDate, null);
      expect(detail.detailEndDate, null);
      expect(detail.detailMemo, null);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final detail1 = PinDetail(
        id: 'detail001',
        detailId: 'detail001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
      );
      final detail2 = PinDetail(
        id: 'detail001',
        detailId: 'detail001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
      );

      expect(detail1, equals(detail2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final detail = PinDetail(
        id: 'detail001',
        detailId: 'detail001',
        pinId: 'pin001',
        tripId: 'trip001',
        groupId: 'group001',
      );

      final updated = detail.copyWith(
        detailName: 'ルーヴル美術館',
        detailMemo: '夕方に訪問',
        detailStartDate: DateTime(2025, 6, 2, 16, 0),
        detailEndDate: DateTime(2025, 6, 2, 19, 0),
      );

      expect(updated.detailName, 'ルーヴル美術館');
      expect(updated.detailMemo, '夕方に訪問');
      expect(updated.detailStartDate, DateTime(2025, 6, 2, 16, 0));
      expect(updated.detailEndDate, DateTime(2025, 6, 2, 19, 0));
    });
  });
}
