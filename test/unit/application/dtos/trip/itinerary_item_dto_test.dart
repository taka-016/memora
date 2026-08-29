import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';

void main() {
  group('ItineraryItemDto', () {
    test('copyWithで値を更新でき、日時とメモをnullにできる', () {
      final dto = ItineraryItemDto(
        id: 'item001',
        tripId: 'trip001',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      final copiedDto = dto.copyWith(
        name: '昼食',
        startDateTime: null,
        endDateTime: null,
        memo: null,
      );

      expect(copiedDto.id, 'item001');
      expect(copiedDto.tripId, 'trip001');
      expect(copiedDto.name, '昼食');
      expect(copiedDto.startDateTime, isNull);
      expect(copiedDto.endDateTime, isNull);
      expect(copiedDto.memo, isNull);
    });
  });
}
