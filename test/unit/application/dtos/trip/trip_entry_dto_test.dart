import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

void main() {
  group('TripEntryDto', () {
    test('copyWithでnullableフィールドをnullに更新できる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '旅行名',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
      );

      final copiedDto = originalDto.copyWith(
        name: null,
        startDate: null,
        endDate: null,
      );

      expect(copiedDto.name, isNull);
      expect(copiedDto.startDate, isNull);
      expect(copiedDto.endDate, isNull);
    });
  });
}
