import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';

void main() {
  group('AndroidWidgetItineraryCacheDto', () {
    test('JSONへ変換して復元できる', () {
      final cache = AndroidWidgetItineraryCacheDto(
        version: 1,
        groupId: 'group001',
        selectedTripId: 'trip001',
        lastUpdatedAt: DateTime(2026, 5, 24, 12, 30),
        trips: [
          AndroidWidgetTripCacheDto(
            id: 'trip001',
            name: '沖縄旅行',
            periodLabel: '2026/5/25 - 2026/5/27',
            startDate: DateTime(2026, 5, 25),
            endDate: DateTime(2026, 5, 27),
            itineraryItems: [
              AndroidWidgetItineraryItemCacheDto(
                id: 'item001',
                name: '朝食',
                timeLabel: '5/25 8:00 - 9:00',
                startDateTime: DateTime(2026, 5, 25, 8),
                endDateTime: DateTime(2026, 5, 25, 9),
                memo: 'ホテルで朝食',
              ),
            ],
          ),
        ],
      );

      final restored = AndroidWidgetItineraryCacheDto.fromJson(
        cache.toJson(),
      );

      expect(restored, cache);
    });
  });
}
