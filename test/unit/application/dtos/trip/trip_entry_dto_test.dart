import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

void main() {
  group('TripEntryDto', () {
    test('必須パラメータのみでコンストラクタが正しく動作する', () {
      const dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
      );

      expect(dto.id, 'trip-entry-123');
      expect(dto.groupId, 'group-456');
      expect(dto.year, 2024);
      expect(dto.name, isNull);
      expect(dto.startDate, isNull);
      expect(dto.endDate, isNull);
      expect(dto.memo, isNull);
      expect(dto.tasks, isNull);
      expect(dto.itineraryItems, isNull);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '持ち物準備',
          isCompleted: false,
        ),
      ];
      const itineraryItems = [
        ItineraryItemDto(id: 'item-1', tripId: 'trip-entry-123', name: '朝食'),
      ];

      final dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '春の旅行',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        memo: '家族旅行のメモ',
        tasks: tasks,
        itineraryItems: itineraryItems,
      );

      expect(dto.name, '春の旅行');
      expect(dto.memo, '家族旅行のメモ');
      expect(dto.tasks, tasks);
      expect(dto.itineraryItems, itineraryItems);
    });

    test('copyWithでオプショナルパラメータを更新できる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '元の旅行名',
        memo: '元のメモ',
        tasks: [
          TaskDto(
            id: 'task-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
      );

      final copiedDto = originalDto.copyWith(
        name: '新しい旅行名',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 3),
        memo: '新しいメモ',
        tasks: [
          TaskDto(
            id: 'task-2',
            tripId: 'trip-entry-123',
            orderIndex: 1,
            name: '予約確認',
            isCompleted: true,
          ),
        ],
      );

      expect(copiedDto.name, '新しい旅行名');
      expect(copiedDto.startDate, DateTime(2024, 6, 1));
      expect(copiedDto.endDate, DateTime(2024, 6, 3));
      expect(copiedDto.memo, '新しいメモ');
      expect(copiedDto.tasks?.single.id, 'task-2');
    });

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
