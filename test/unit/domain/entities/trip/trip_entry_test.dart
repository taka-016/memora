import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('TripEntry', () {
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
  });
}
