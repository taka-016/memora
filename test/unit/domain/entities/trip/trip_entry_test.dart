import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('TripEntry', () {
    test('インスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        year: 2025,
        name: 'テスト旅行',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        memo: 'テストメモ',
        pins: [
          Pin(
            pinId: 'pin1',
            tripId: 'abc123',
            groupId: 'group456',
            latitude: 0,
            longitude: 0,
            locationName: 'パリ',
            visitStartDateTime: DateTime(2025, 6, 2),
            visitEndDateTime: DateTime(2025, 6, 3),
            memo: 'エッフェル塔',
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
        itineraryItems: [
          ItineraryItem(
            id: 'item-1',
            tripId: 'abc123',
            name: '朝食',
            startDateTime: DateTime(2025, 6, 2, 8),
            endDateTime: DateTime(2025, 6, 2, 9),
            memo: 'ホテルで朝食',
          ),
        ],
      );
      expect(entry.id, 'abc123');
      expect(entry.groupId, 'group456');
      expect(entry.name, 'テスト旅行');
      expect(entry.startDate, DateTime(2025, 6, 1));
      expect(entry.endDate, DateTime(2025, 6, 10));
      expect(entry.memo, 'テストメモ');
      expect(entry.pins, hasLength(1));
      expect(entry.year, 2025);
      expect(entry.pins.first.locationName, 'パリ');
      expect(entry.pins.first.memo, 'エッフェル塔');
      expect(entry.tasks, hasLength(1));
      expect(entry.tasks.first.name, '持ち物準備');
      expect(entry.itineraryItems, hasLength(1));
      expect(entry.itineraryItems.first.name, '朝食');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        year: 2025,
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
      );
      expect(entry.id, 'abc123');
      expect(entry.groupId, 'group456');
      expect(entry.name, null);
      expect(entry.startDate, DateTime(2025, 6, 1));
      expect(entry.endDate, DateTime(2025, 6, 10));
      expect(entry.memo, null);
      expect(entry.year, 2025);
      expect(entry.pins, isEmpty);
      expect(entry.tasks, isEmpty);
      expect(entry.itineraryItems, isEmpty);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final entry1 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        year: 2025,
        name: 'テスト旅行',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        memo: 'テストメモ',
        pins: const [],
        tasks: const [],
        itineraryItems: const [],
      );
      final entry2 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        year: 2025,
        name: 'テスト旅行',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        memo: 'テストメモ',
        pins: const [],
        tasks: const [],
        itineraryItems: const [],
      );
      expect(entry1, equals(entry2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        year: 2025,
        name: 'テスト旅行',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        memo: 'テストメモ',
        pins: const [],
        tasks: const [],
      );
      final updatedEntry = entry.copyWith(
        name: '新しい旅行',
        endDate: DateTime(2025, 6, 15),
        pins: [
          Pin(
            pinId: 'pin2',
            tripId: 'abc123',
            groupId: 'group456',
            latitude: 0,
            longitude: 0,
            locationName: 'ローマ',
            visitStartDateTime: DateTime(2025, 6, 12),
            visitEndDateTime: DateTime(2025, 6, 14),
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
        itineraryItems: [
          ItineraryItem(id: 'item-2', tripId: 'abc123', name: '夕食'),
        ],
      );
      expect(updatedEntry.id, 'abc123');
      expect(updatedEntry.groupId, 'group456');
      expect(updatedEntry.name, '新しい旅行');
      expect(updatedEntry.startDate, DateTime(2025, 6, 1));
      expect(updatedEntry.endDate, DateTime(2025, 6, 15));
      expect(updatedEntry.memo, 'テストメモ');
      expect(updatedEntry.pins, hasLength(1));
      expect(updatedEntry.tasks, hasLength(1));
      expect(updatedEntry.tasks.first.name, 'ホテル予約');
      expect(updatedEntry.itineraryItems, hasLength(1));
      expect(updatedEntry.itineraryItems.first.name, '夕食');
    });

    test('旅行期間外の訪問場所を含むと例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'abc123',
          groupId: 'group456',
          year: 2025,
          startDate: DateTime(2025, 6, 1),
          endDate: DateTime(2025, 6, 10),
          pins: [
            Pin(
              pinId: 'pin1',
              tripId: 'abc123',
              groupId: 'group456',
              latitude: 0,
              longitude: 0,
              visitStartDateTime: DateTime(2025, 5, 31),
              visitEndDateTime: DateTime(2025, 6, 2),
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
        year: 2025,
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
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

    test('startDateとendDateが未設定でもyearが必須で生成できる', () {
      final entry = TripEntry(id: 'trip789', groupId: 'group456', year: 2025);

      expect(entry.startDate, isNull);
      expect(entry.endDate, isNull);
      expect(entry.year, 2025);
    });

    test('旅行期間未設定時はpinの訪問日時がyearと異なると例外', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          year: 2025,
          pins: [
            Pin(
              pinId: 'pin1',
              tripId: 'trip123',
              groupId: 'group456',
              latitude: 0,
              longitude: 0,
              visitStartDateTime: DateTime(2024, 6, 1),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('旅行期間未設定時でもpinの訪問日時がyearと一致すれば生成可能', () {
      final entry = TripEntry(
        id: 'trip123',
        groupId: 'group456',
        year: 2025,
        pins: [
          Pin(
            pinId: 'pin1',
            tripId: 'trip123',
            groupId: 'group456',
            latitude: 0,
            longitude: 0,
            visitStartDateTime: DateTime(2025, 6, 1),
            visitEndDateTime: DateTime(2025, 6, 2),
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
          year: 2025,
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
          year: 2025,
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
          year: 2025,
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
          year: 2025,
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

    test('旅行期間の開始2日前から終了2日後までの旅程項目は生成できる', () {
      final entry = TripEntry(
        id: 'trip123',
        groupId: 'group456',
        year: 2025,
        startDate: DateTime(2025, 6, 10),
        endDate: DateTime(2025, 6, 12),
        itineraryItems: [
          ItineraryItem(
            id: 'item-1',
            tripId: 'trip123',
            name: '前泊移動',
            startDateTime: DateTime(2025, 6, 8),
          ),
          ItineraryItem(
            id: 'item-2',
            tripId: 'trip123',
            name: '帰宅',
            endDateTime: DateTime(2025, 6, 14, 23, 59),
          ),
        ],
      );

      expect(entry.itineraryItems, hasLength(2));
    });

    test('旅行期間未設定時は旅程項目の日時がyearと異なっていても生成できる', () {
      final entry = TripEntry(
        id: 'trip123',
        groupId: 'group456',
        year: 2025,
        itineraryItems: [
          ItineraryItem(
            id: 'item-1',
            tripId: 'trip123',
            name: '年またぎ移動',
            startDateTime: DateTime(2024, 12, 31, 23),
            endDateTime: DateTime(2026, 1, 1),
          ),
        ],
      );

      expect(entry.itineraryItems, hasLength(1));
    });

    test('旅行期間の開始2日前より前の旅程項目を含むと例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          year: 2025,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 12),
          itineraryItems: [
            ItineraryItem(
              id: 'item-1',
              tripId: 'trip123',
              name: '早すぎる移動',
              startDateTime: DateTime(2025, 6, 7, 23, 59),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('旅行期間の終了2日後より後の旅程項目を含むと例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'trip123',
          groupId: 'group456',
          year: 2025,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 12),
          itineraryItems: [
            ItineraryItem(
              id: 'item-1',
              tripId: 'trip123',
              name: '遅すぎる帰宅',
              endDateTime: DateTime(2025, 6, 15),
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
