import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
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
      expect(dto.pins, isNull);
      expect(dto.tasks, isNull);
      expect(dto.itineraryItems, isNull);
    });

    test('期間を指定すると開始日/終了日が保持される', () {
      final startDate = DateTime(2024, 5, 1);
      final endDate = DateTime(2024, 5, 3);

      final dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        startDate: startDate,
        endDate: endDate,
      );

      expect(dto.startDate, startDate);
      expect(dto.endDate, endDate);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      final pins = [
        PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0),
        PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0),
      ];
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
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '朝食',
        ),
      ];

      final dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '春の旅行',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        memo: '家族旅行のメモ',
        pins: pins,
        tasks: tasks,
        itineraryItems: itineraryItems,
      );

      expect(dto.name, '春の旅行');
      expect(dto.memo, '家族旅行のメモ');
      expect(dto.pins, pins);
      expect(dto.tasks, tasks);
      expect(dto.itineraryItems, itineraryItems);
    });

    test('copyWithで必須パラメータを更新できる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
      );

      final copiedDto = originalDto.copyWith(
        id: 'trip-entry-999',
        groupId: 'group-888',
        year: 2025,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 5),
      );

      expect(copiedDto.id, 'trip-entry-999');
      expect(copiedDto.groupId, 'group-888');
      expect(copiedDto.year, 2025);
      expect(copiedDto.startDate, DateTime(2025, 1, 1));
      expect(copiedDto.endDate, DateTime(2025, 1, 5));
    });

    test('copyWithでオプショナルパラメータを更新できる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '元の旅行名',
        memo: '元のメモ',
        pins: [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)],
        tasks: [
          TaskDto(
            id: 'task-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
        itineraryItems: const [
          ItineraryItemDto(
            id: 'item-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            name: '朝食',
          ),
        ],
      );

      final copiedDto = originalDto.copyWith(
        name: '新しい旅行名',
        memo: '新しいメモ',
        pins: [PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0)],
        tasks: [
          TaskDto(
            id: 'task-2',
            tripId: 'trip-entry-123',
            orderIndex: 1,
            name: '予約確認',
            isCompleted: true,
          ),
        ],
        itineraryItems: const [
          ItineraryItemDto(
            id: 'item-2',
            tripId: 'trip-entry-123',
            orderIndex: 1,
            name: '観光',
          ),
        ],
      );

      expect(copiedDto.name, '新しい旅行名');
      expect(copiedDto.memo, '新しいメモ');
      expect(copiedDto.pins?.first.pinId, 'pin-2');
      expect(copiedDto.tasks?.first.id, 'task-2');
      expect(copiedDto.itineraryItems?.first.id, 'item-2');
    });

    test('copyWithで開始日と終了日をnullにできる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
      );

      final copiedDto = originalDto.copyWith(startDate: null, endDate: null);

      expect(copiedDto.startDate, isNull);
      expect(copiedDto.endDate, isNull);
    });

    test('copyWithで不正な型を渡すとArgumentErrorが発生する', () {
      const originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
      );

      expect(
        () => originalDto.copyWith(name: 123),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => originalDto.copyWith(startDate: '2025/01/01'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => originalDto.copyWith(pins: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => originalDto.copyWith(itineraryItems: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyWithで何も指定しなければ元の値を保持する', () {
      final pins = [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];
      const itineraryItems = [
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '朝食',
        ),
      ];
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '旅行名',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        memo: '旅行のメモ',
        pins: pins,
        tasks: tasks,
        itineraryItems: itineraryItems,
      );

      final copiedDto = originalDto.copyWith();

      expect(copiedDto, equals(originalDto));
    });

    test('同じ値を持つインスタンスは等しい', () {
      final pins = [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];
      const itineraryItems = [
        ItineraryItemDto(
          id: 'item-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '朝食',
        ),
      ];

      final dto1 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '春の旅行',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        memo: '家族旅行のメモ',
        pins: pins,
        tasks: tasks,
        itineraryItems: itineraryItems,
      );

      final dto2 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '春の旅行',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        memo: '家族旅行のメモ',
        pins: pins,
        tasks: tasks,
        itineraryItems: itineraryItems,
      );

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      final dto1 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        year: 2024,
        name: '旅行A',
        startDate: DateTime(2024, 5, 1),
        endDate: DateTime(2024, 5, 3),
        memo: 'メモA',
        pins: [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)],
        tasks: [
          TaskDto(
            id: 'task-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
        ],
        itineraryItems: const [
          ItineraryItemDto(
            id: 'item-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            name: '朝食',
          ),
        ],
      );

      final dto2 = TripEntryDto(
        id: 'trip-entry-999',
        groupId: 'group-888',
        year: 2025,
        name: '旅行B',
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 6, 3),
        memo: 'メモB',
        pins: [PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0)],
        tasks: [
          TaskDto(
            id: 'task-2',
            tripId: 'trip-entry-999',
            orderIndex: 1,
            name: '予約確認',
            isCompleted: true,
          ),
        ],
        itineraryItems: const [
          ItineraryItemDto(
            id: 'item-2',
            tripId: 'trip-entry-999',
            orderIndex: 1,
            name: '観光',
          ),
        ],
      );

      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
