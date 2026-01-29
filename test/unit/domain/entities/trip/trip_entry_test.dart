import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('TripEntry', () {
    test('インスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripYear: 2025,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: [
          Pin(
            pinId: 'pin1',
            tripId: 'abc123',
            groupId: 'group456',
            latitude: 0,
            longitude: 0,
            locationName: 'パリ',
            visitStartDate: DateTime(2025, 6, 2),
            visitEndDate: DateTime(2025, 6, 3),
            visitMemo: 'エッフェル塔',
          ),
        ],
        routes: [
          Route(
            tripId: 'abc123',
            orderIndex: 0,
            departurePinId: 'pin1',
            arrivalPinId: 'pin2',
            travelMode: TravelMode.drive,
          ),
        ],
        tasks: [
          Task(
            id: 'task-1',
            tripId: 'abc123',
            orderIndex: 0,
            name: '持ち物準備',
            isCompleted: false,
          ),
        ],
      );
      expect(entry.id, 'abc123');
      expect(entry.groupId, 'group456');
      expect(entry.tripName, 'テスト旅行');
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.tripMemo, 'テストメモ');
      expect(entry.pins, hasLength(1));
      expect(entry.tripYear, 2025);
      expect(entry.pins.first.locationName, 'パリ');
      expect(entry.pins.first.visitMemo, 'エッフェル塔');
      expect(entry.routes, hasLength(1));
      expect(entry.routes.first.orderIndex, 0);
      expect(entry.tasks, hasLength(1));
      expect(entry.tasks.first.name, '持ち物準備');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripYear: 2025,
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
      );
      expect(entry.id, 'abc123');
      expect(entry.groupId, 'group456');
      expect(entry.tripName, null);
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.tripMemo, null);
      expect(entry.tripYear, 2025);
      expect(entry.pins, isEmpty);
      expect(entry.tasks, isEmpty);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final entry1 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripYear: 2025,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: const [],
        routes: const [],
        tasks: const [],
      );
      final entry2 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripYear: 2025,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: const [],
        routes: const [],
        tasks: const [],
      );
      expect(entry1, equals(entry2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripYear: 2025,
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: const [],
        routes: const [],
        tasks: const [],
      );
      final updatedEntry = entry.copyWith(
        tripName: '新しい旅行',
        tripEndDate: DateTime(2025, 6, 15),
        pins: [
          Pin(
            pinId: 'pin2',
            tripId: 'abc123',
            groupId: 'group456',
            latitude: 0,
            longitude: 0,
            locationName: 'ローマ',
            visitStartDate: DateTime(2025, 6, 12),
            visitEndDate: DateTime(2025, 6, 14),
          ),
        ],
        routes: [
          Route(
            tripId: 'abc123',
            orderIndex: 1,
            departurePinId: 'pin2',
            arrivalPinId: 'pin3',
            travelMode: TravelMode.walk,
          ),
        ],
        tasks: [
          Task(
            id: 'task-2',
            tripId: 'abc123',
            orderIndex: 1,
            name: 'ホテル予約',
            isCompleted: true,
          ),
        ],
      );
      expect(updatedEntry.id, 'abc123');
      expect(updatedEntry.groupId, 'group456');
      expect(updatedEntry.tripName, '新しい旅行');
      expect(updatedEntry.tripStartDate, DateTime(2025, 6, 1));
      expect(updatedEntry.tripEndDate, DateTime(2025, 6, 15));
      expect(updatedEntry.tripMemo, 'テストメモ');
      expect(updatedEntry.pins, hasLength(1));
      expect(updatedEntry.routes, hasLength(1));
      expect(updatedEntry.routes.first.orderIndex, 1);
      expect(updatedEntry.tasks, hasLength(1));
      expect(updatedEntry.tasks.first.name, 'ホテル予約');
    });

    test('旅行期間外の訪問場所を含むと例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'abc123',
          groupId: 'group456',
          tripYear: 2025,
          tripStartDate: DateTime(2025, 6, 1),
          tripEndDate: DateTime(2025, 6, 10),
          pins: [
            Pin(
              pinId: 'pin1',
              tripId: 'abc123',
              groupId: 'group456',
              latitude: 0,
              longitude: 0,
              visitStartDate: DateTime(2025, 5, 31),
              visitEndDate: DateTime(2025, 6, 2),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('routesに含まれるRouteの順序が保持される', () {
      final entry = TripEntry(
        id: 'trip123',
        groupId: 'group456',
        tripYear: 2025,
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        routes: [
          Route(
            tripId: 'trip123',
            orderIndex: 1,
            departurePinId: 'pinB',
            arrivalPinId: 'pinC',
            travelMode: TravelMode.walk,
          ),
          Route(
            tripId: 'trip123',
            orderIndex: 0,
            departurePinId: 'pinA',
            arrivalPinId: 'pinB',
            travelMode: TravelMode.drive,
          ),
        ],
      );

      expect(entry.routes[0].orderIndex, 1);
      expect(entry.routes[1].orderIndex, 0);
    });

    test('routesのorderIndexが重複していると例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          tripYear: 2025,
          tripStartDate: DateTime(2025, 6, 1),
          tripEndDate: DateTime(2025, 6, 10),
          routes: [
            Route(
              tripId: 'trip123',
              orderIndex: 0,
              departurePinId: 'pinA',
              arrivalPinId: 'pinB',
              travelMode: TravelMode.drive,
            ),
            Route(
              tripId: 'trip123',
              orderIndex: 0,
              departurePinId: 'pinB',
              arrivalPinId: 'pinC',
              travelMode: TravelMode.walk,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('タスクのorderIndexが重複していても生成できる', () {
      final entry = TripEntry(
        id: 'trip123',
        groupId: 'group456',
        tripYear: 2025,
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tasks: [
          Task(
            id: 'task-1',
            tripId: 'trip123',
            orderIndex: 0,
            name: '準備',
            isCompleted: false,
          ),
          Task(
            id: 'task-2',
            tripId: 'trip123',
            orderIndex: 0,
            name: '確認',
            isCompleted: true,
          ),
        ],
      );

      expect(entry.tasks, hasLength(2));
    });

    test('tripStartDateとtripEndDateが未設定でもtripYearが必須で生成できる', () {
      final entry = TripEntry(
        id: 'trip789',
        groupId: 'group456',
        tripYear: 2025,
      );

      expect(entry.tripStartDate, isNull);
      expect(entry.tripEndDate, isNull);
      expect(entry.tripYear, 2025);
    });

    test('旅行期間未設定時はpinの訪問日時がtripYearと異なると例外', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          tripYear: 2025,
          pins: [
            Pin(
              pinId: 'pin1',
              tripId: 'trip123',
              groupId: 'group456',
              latitude: 0,
              longitude: 0,
              visitStartDate: DateTime(2024, 6, 1),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('旅行期間未設定時でもpinの訪問日時がtripYearと一致すれば生成可能', () {
      final entry = TripEntry(
        id: 'trip123',
        groupId: 'group456',
        tripYear: 2025,
        pins: [
          Pin(
            pinId: 'pin1',
            tripId: 'trip123',
            groupId: 'group456',
            latitude: 0,
            longitude: 0,
            visitStartDate: DateTime(2025, 6, 1),
            visitEndDate: DateTime(2025, 6, 2),
          ),
        ],
      );

      expect(entry.pins, hasLength(1));
    });

    test('存在しない親タスクが設定されていると例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          tripYear: 2025,
          tasks: [
            Task(
              id: 'task-1',
              tripId: 'trip123',
              orderIndex: 0,
              name: '親タスク',
              isCompleted: false,
            ),
            Task(
              id: 'task-2',
              tripId: 'trip123',
              orderIndex: 1,
              name: '子タスク',
              isCompleted: false,
              parentTaskId: 'missing-parent',
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('親タスクが完了で子タスクが未完了の場合は例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          tripYear: 2025,
          tasks: [
            Task(
              id: 'task-1',
              tripId: 'trip123',
              orderIndex: 0,
              name: '親タスク',
              isCompleted: true,
            ),
            Task(
              id: 'task-2',
              tripId: 'trip123',
              orderIndex: 1,
              name: '子タスク',
              isCompleted: false,
              parentTaskId: 'task-1',
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('親タスクと子タスクが両方とも完了している場合は正常にインスタンスが生成される', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          tripYear: 2025,
          tasks: [
            Task(
              id: 'task-1',
              tripId: 'trip123',
              orderIndex: 0,
              name: '親タスク',
              isCompleted: true,
            ),
            Task(
              id: 'task-2',
              tripId: 'trip123',
              orderIndex: 1,
              name: '子タスク',
              isCompleted: true,
              parentTaskId: 'task-1',
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test('親タスクが完了で複数の子タスクのうち一つでも未完了の場合は例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          tripYear: 2025,
          tasks: [
            Task(
              id: 'task-1',
              tripId: 'trip123',
              orderIndex: 0,
              name: '親タスク',
              isCompleted: true,
            ),
            Task(
              id: 'task-2',
              tripId: 'trip123',
              orderIndex: 1,
              name: '子タスク1（完了）',
              isCompleted: true,
              parentTaskId: 'task-1',
            ),
            Task(
              id: 'task-3',
              tripId: 'trip123',
              orderIndex: 2,
              name: '子タスク2（未完了）',
              isCompleted: false,
              parentTaskId: 'task-1',
            ),
            Task(
              id: 'task-4',
              tripId: 'trip123',
              orderIndex: 3,
              name: '子タスク3（完了）',
              isCompleted: true,
              parentTaskId: 'task-1',
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
