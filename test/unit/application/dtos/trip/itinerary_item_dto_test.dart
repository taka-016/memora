import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';

void main() {
  group('ItineraryItemDto', () {
    test('locationIdを保持できる', () {
      const dto = ItineraryItemDto(
        id: 'item-1',
        tripId: 'trip-1',
        name: '昼食',
        locationId: 'location-1',
      );

      expect(dto.locationId, 'location-1');
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      final dto = ItineraryItemDto(
        id: 'item001',
        tripId: 'trip001',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      expect(dto.id, 'item001');
      expect(dto.tripId, 'trip001');
      expect(dto.name, '朝食');
      expect(dto.startDateTime, DateTime(2024, 1, 2, 8));
      expect(dto.endDateTime, DateTime(2024, 1, 2, 9));
      expect(dto.memo, 'ホテルで朝食');
    });

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

    test('同じ値を持つインスタンスは等しい', () {
      final dto1 = ItineraryItemDto(
        id: 'item001',
        tripId: 'trip001',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );
      final dto2 = ItineraryItemDto(
        id: 'item001',
        tripId: 'trip001',
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      expect(dto1, dto2);
      expect(dto1.hashCode, dto2.hashCode);
    });
  });
}
