import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('ItineraryItem', () {
    test('nameが空の場合は例外が発生する', () {
      expect(
        () => ItineraryItem(id: 'item001', tripId: 'trip001', name: '  '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('終了日時が開始日時より前の場合は例外が発生する', () {
      expect(
        () => ItineraryItem(
          id: 'item001',
          tripId: 'trip001',
          name: '朝食',
          startDateTime: DateTime(2024, 1, 2, 9),
          endDateTime: DateTime(2024, 1, 2, 8),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
