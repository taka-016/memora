import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('TripEntry', () {
    test('旅行情報と子要素を保持する', () {
      final entry = TripEntry(
        id: 'trip1',
        groupId: 'group1',
        year: 2024,
        name: 'パリ旅行',
        startDate: DateTime(2024, 7),
        endDate: DateTime(2024, 7, 10),
        memo: '家族旅行',
        locations: [
          Location(
            id: 'location1',
            tripId: 'trip1',
            groupId: 'group1',
            name: 'パリ',
            latitude: 48.8566,
            longitude: 2.3522,
          ),
        ],
        tasks: [
          Task(
            id: 'task1',
            tripId: 'trip1',
            orderIndex: 0,
            name: '予約確認',
            isCompleted: false,
          ),
        ],
        itineraryItems: [
          ItineraryItem(
            id: 'item1',
            tripId: 'trip1',
            name: '朝食',
            startDateTime: DateTime(2024, 7, 1, 8),
          ),
        ],
      );

      expect(entry.id, 'trip1');
      expect(entry.groupId, 'group1');
      expect(entry.locations, hasLength(1));
      expect(entry.tasks, hasLength(1));
      expect(entry.itineraryItems, hasLength(1));
    });

    test('終了日が開始日より前の場合は例外を投げる', () {
      expect(
        () => TripEntry(
          id: 'trip1',
          groupId: 'group1',
          year: 2024,
          startDate: DateTime(2024, 7, 10),
          endDate: DateTime(2024, 7),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('存在しない親タスクが設定されている場合は例外を投げる', () {
      expect(
        () => TripEntry(
          id: 'trip1',
          groupId: 'group1',
          year: 2024,
          tasks: [
            Task(
              id: 'task1',
              tripId: 'trip1',
              orderIndex: 0,
              parentTaskId: 'missing',
              name: '子タスク',
              isCompleted: false,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('旅程項目の日時が許容範囲外の場合は例外を投げる', () {
      expect(
        () => TripEntry(
          id: 'trip1',
          groupId: 'group1',
          year: 2024,
          startDate: DateTime(2024, 7, 10),
          endDate: DateTime(2024, 7, 12),
          itineraryItems: [
            ItineraryItem(
              id: 'item1',
              tripId: 'trip1',
              name: '早すぎる予定',
              startDateTime: DateTime(2024, 7, 7, 23, 59),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('copyWithで値を更新できる', () {
      final entry = TripEntry(id: 'trip1', groupId: 'group1', year: 2024);

      final updated = entry.copyWith(name: '更新後', memo: 'メモ');

      expect(updated.name, '更新後');
      expect(updated.memo, 'メモ');
      expect(updated.id, 'trip1');
    });
  });
}
