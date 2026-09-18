import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/android_widget/android_widget_itinerary_cache_dto.dart';
import 'package:memora/application/models/app_mode.dart';

void main() {
  group('AndroidWidgetItineraryCacheDto', () {
    test('JSONへ変換して復元できる', () {
      final cache = AndroidWidgetItineraryCacheDto(
        version: 1,
        sourceMode: AppMode.offline,
        groupId: 'group001',
        selectedItineraryDateId: 'trip001_2026-05-25',
        lastUpdatedAt: DateTime(2026, 5, 24, 12, 30),
        itineraryDates: [
          AndroidWidgetItineraryDateCacheDto(
            id: 'trip001_2026-05-25',
            tripId: 'trip001',
            tripName: '沖縄旅行',
            tripPeriodLabel: '2026/5/25 - 2026/5/27',
            dateLabel: '2026/5/25',
            date: DateTime(2026, 5, 25),
            itineraryItems: [
              AndroidWidgetItineraryItemCacheDto(
                id: 'item001',
                name: '朝食',
                timeLabel: '8:00 - 9:00',
                startDateTime: DateTime(2026, 5, 25, 8),
                endDateTime: DateTime(2026, 5, 25, 9),
              ),
            ],
          ),
        ],
      );

      final restored = AndroidWidgetItineraryCacheDto.fromJson(cache.toJson());

      expect(restored, cache);
    });

    test('生成元モードがない従来キャッシュはオンラインとして復元する', () {
      final restored = AndroidWidgetItineraryCacheDto.fromJson({
        'version': 1,
        'groupId': 'group001',
      });

      expect(restored.sourceMode, AppMode.online);
    });

    test('旅程項目のメモはJSONに出力しない', () {
      final item = AndroidWidgetItineraryItemCacheDto(
        id: 'item001',
        name: '朝食',
        timeLabel: '8:00 - 9:00',
        startDateTime: DateTime(2026, 5, 25, 8),
        endDateTime: DateTime(2026, 5, 25, 9),
      );

      expect(item.toJson().containsKey('memo'), isFalse);
    });
  });
}
