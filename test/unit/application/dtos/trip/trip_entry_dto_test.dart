import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';

void main() {
  group('TripEntryDto', () {
    test('必須パラメータのみでコンストラクタが正しく動作する', () {
      const dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
      );

      expect(dto.id, 'trip-entry-123');
      expect(dto.groupId, 'group-456');
      expect(dto.tripYear, 2024);
      expect(dto.tripName, isNull);
      expect(dto.tripStartDate, isNull);
      expect(dto.tripEndDate, isNull);
      expect(dto.tripMemo, isNull);
      expect(dto.pins, isNull);
      expect(dto.routes, isNull);
      expect(dto.tasks, isNull);
    });

    test('期間を指定すると開始日/終了日が保持される', () {
      final tripStartDate = DateTime(2024, 5, 1);
      final tripEndDate = DateTime(2024, 5, 3);

      final dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripStartDate: tripStartDate,
        tripEndDate: tripEndDate,
      );

      expect(dto.tripStartDate, tripStartDate);
      expect(dto.tripEndDate, tripEndDate);
    });

    test('全パラメータでコンストラクタが正しく動作する', () {
      final pins = [
        PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0),
        PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0),
      ];
      final routes = [
        RouteDto(
          id: 'route-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          departurePinId: 'pin-1',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
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

      final dto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripName: '春の旅行',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: '家族旅行のメモ',
        pins: pins,
        routes: routes,
        tasks: tasks,
      );

      expect(dto.tripName, '春の旅行');
      expect(dto.tripMemo, '家族旅行のメモ');
      expect(dto.pins, pins);
      expect(dto.routes, routes);
      expect(dto.tasks, tasks);
    });

    test('copyWithで必須パラメータを更新できる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
      );

      final copiedDto = originalDto.copyWith(
        id: 'trip-entry-999',
        groupId: 'group-888',
        tripYear: 2025,
        tripStartDate: DateTime(2025, 1, 1),
        tripEndDate: DateTime(2025, 1, 5),
      );

      expect(copiedDto.id, 'trip-entry-999');
      expect(copiedDto.groupId, 'group-888');
      expect(copiedDto.tripYear, 2025);
      expect(copiedDto.tripStartDate, DateTime(2025, 1, 1));
      expect(copiedDto.tripEndDate, DateTime(2025, 1, 5));
    });

    test('copyWithでオプショナルパラメータを更新できる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripName: '元の旅行名',
        tripMemo: '元のメモ',
        pins: [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)],
        routes: [
          RouteDto(
            id: 'route-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            departurePinId: 'pin-1',
            arrivalPinId: 'pin-1b',
            travelMode: TravelMode.walk,
          ),
        ],
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
        tripName: '新しい旅行名',
        tripMemo: '新しいメモ',
        pins: [PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0)],
        routes: [
          RouteDto(
            id: 'route-2',
            tripId: 'trip-entry-123',
            orderIndex: 1,
            departurePinId: 'pin-1b',
            arrivalPinId: 'pin-2',
            travelMode: TravelMode.drive,
          ),
        ],
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

      expect(copiedDto.tripName, '新しい旅行名');
      expect(copiedDto.tripMemo, '新しいメモ');
      expect(copiedDto.pins?.first.pinId, 'pin-2');
      expect(copiedDto.routes?.first.id, 'route-2');
      expect(copiedDto.tasks?.first.id, 'task-2');
    });

    test('copyWithで開始日と終了日をnullにできる', () {
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
      );

      final copiedDto = originalDto.copyWith(
        tripStartDate: null,
        tripEndDate: null,
      );

      expect(copiedDto.tripStartDate, isNull);
      expect(copiedDto.tripEndDate, isNull);
    });

    test('copyWithで何も指定しなければ元の値を保持する', () {
      final pins = [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)];
      final routes = [
        RouteDto(
          id: 'route-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          departurePinId: 'pin-1',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
      ];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];
      final originalDto = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripName: '旅行名',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: '旅行のメモ',
        pins: pins,
        routes: routes,
        tasks: tasks,
      );

      final copiedDto = originalDto.copyWith();

      expect(copiedDto, equals(originalDto));
    });

    test('同じ値を持つインスタンスは等しい', () {
      final pins = [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)];
      final routes = [
        RouteDto(
          id: 'route-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          departurePinId: 'pin-1',
          arrivalPinId: 'pin-2',
          travelMode: TravelMode.drive,
        ),
      ];
      final tasks = [
        TaskDto(
          id: 'task-1',
          tripId: 'trip-entry-123',
          orderIndex: 0,
          name: '準備',
          isCompleted: false,
        ),
      ];

      final dto1 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripName: '春の旅行',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: '家族旅行のメモ',
        pins: pins,
        routes: routes,
        tasks: tasks,
      );

      final dto2 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripName: '春の旅行',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: '家族旅行のメモ',
        pins: pins,
        routes: routes,
        tasks: tasks,
      );

      expect(dto1, equals(dto2));
      expect(dto1.hashCode, equals(dto2.hashCode));
    });

    test('異なる値を持つインスタンスは等しくない', () {
      final dto1 = TripEntryDto(
        id: 'trip-entry-123',
        groupId: 'group-456',
        tripYear: 2024,
        tripName: '旅行A',
        tripStartDate: DateTime(2024, 5, 1),
        tripEndDate: DateTime(2024, 5, 3),
        tripMemo: 'メモA',
        pins: [PinDto(pinId: 'pin-1', latitude: 35.0, longitude: 139.0)],
        routes: [
          RouteDto(
            id: 'route-1',
            tripId: 'trip-entry-123',
            orderIndex: 0,
            departurePinId: 'pin-1',
            arrivalPinId: 'pin-2',
            travelMode: TravelMode.drive,
          ),
        ],
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

      final dto2 = TripEntryDto(
        id: 'trip-entry-999',
        groupId: 'group-888',
        tripYear: 2025,
        tripName: '旅行B',
        tripStartDate: DateTime(2024, 6, 1),
        tripEndDate: DateTime(2024, 6, 3),
        tripMemo: 'メモB',
        pins: [PinDto(pinId: 'pin-2', latitude: 36.0, longitude: 140.0)],
        routes: [
          RouteDto(
            id: 'route-2',
            tripId: 'trip-entry-999',
            orderIndex: 0,
            departurePinId: 'pin-2',
            arrivalPinId: 'pin-3',
            travelMode: TravelMode.walk,
          ),
        ],
        tasks: [
          TaskDto(
            id: 'task-2',
            tripId: 'trip-entry-999',
            orderIndex: 1,
            name: '予約確認',
            isCompleted: true,
          ),
        ],
      );

      expect(dto1, isNot(equals(dto2)));
      expect(dto1.hashCode, isNot(equals(dto2.hashCode)));
    });
  });
}
