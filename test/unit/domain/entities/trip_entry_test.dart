import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/entities/pin_detail.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

void main() {
  group('TripEntry', () {
    test('インスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
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
            details: [
              PinDetail(
                pinId: 'pin1',
                name: '午前観光',
                startDate: DateTime(2025, 6, 2, 9),
                endDate: DateTime(2025, 6, 2, 12),
                memo: 'ルーブル美術館などを見学',
              ),
            ],
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
      expect(entry.pins.first.locationName, 'パリ');
      expect(entry.pins.first.visitMemo, 'エッフェル塔');
      expect(entry.pins.first.details, hasLength(1));
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
      );
      expect(entry.id, 'abc123');
      expect(entry.groupId, 'group456');
      expect(entry.tripName, null);
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.tripMemo, null);
      expect(entry.pins, isEmpty);
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final entry1 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: const [],
      );
      final entry2 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: const [],
      );
      expect(entry1, equals(entry2));
    });

    test('copyWithメソッドが正しく動作する', () {
      final entry = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
        pins: const [],
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
      );
      expect(updatedEntry.id, 'abc123');
      expect(updatedEntry.groupId, 'group456');
      expect(updatedEntry.tripName, '新しい旅行');
      expect(updatedEntry.tripStartDate, DateTime(2025, 6, 1));
      expect(updatedEntry.tripEndDate, DateTime(2025, 6, 15));
      expect(updatedEntry.tripMemo, 'テストメモ');
      expect(updatedEntry.pins, hasLength(1));
    });

    test('旅行期間外の訪問場所を含むと例外が発生する', () {
      expect(
        () => TripEntry(
          id: 'abc123',
          groupId: 'group456',
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
  });
}
