import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('ItineraryItem', () {
    test('インスタンス生成が正しく行われる', () {
      final item = ItineraryItem(
        id: 'item001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      expect(item.id, 'item001');
      expect(item.tripId, 'trip001');
      expect(item.orderIndex, 0);
      expect(item.name, '朝食');
      expect(item.startDateTime, DateTime(2024, 1, 2, 8));
      expect(item.endDateTime, DateTime(2024, 1, 2, 9));
      expect(item.memo, 'ホテルで朝食');
    });

    test('copyWithメソッドが正しく動作する', () {
      final item = ItineraryItem(
        id: 'item001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '朝食',
      );

      final updatedItem = item.copyWith(
        orderIndex: 1,
        name: '昼食',
        memo: '予約確認',
      );

      expect(updatedItem.id, 'item001');
      expect(updatedItem.tripId, 'trip001');
      expect(updatedItem.orderIndex, 1);
      expect(updatedItem.name, '昼食');
      expect(updatedItem.memo, '予約確認');
    });

    test('nameが空の場合は例外が発生する', () {
      expect(
        () => ItineraryItem(
          id: 'item001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '  ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('orderIndexが0未満の場合は例外が発生する', () {
      expect(
        () => ItineraryItem(
          id: 'item001',
          tripId: 'trip001',
          orderIndex: -1,
          name: '朝食',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('終了日時が開始日時より前の場合は例外が発生する', () {
      expect(
        () => ItineraryItem(
          id: 'item001',
          tripId: 'trip001',
          orderIndex: 0,
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 9),
          endDateTime: DateTime(2024, 1, 2, 8),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
