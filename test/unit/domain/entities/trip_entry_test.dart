import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_entry.dart';

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
      );
      expect(entry.id, 'abc123');
      expect(entry.groupId, 'group456');
      expect(entry.tripName, 'テスト旅行');
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.tripMemo, 'テストメモ');
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
    });

    test('同じプロパティを持つインスタンス同士は等価である', () {
      final entry1 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
      );
      final entry2 = TripEntry(
        id: 'abc123',
        groupId: 'group456',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
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
      );
      final updatedEntry = entry.copyWith(
        tripName: '新しい旅行',
        tripEndDate: DateTime(2025, 6, 15),
      );
      expect(updatedEntry.id, 'abc123');
      expect(updatedEntry.groupId, 'group456');
      expect(updatedEntry.tripName, '新しい旅行');
      expect(updatedEntry.tripStartDate, DateTime(2025, 6, 1));
      expect(updatedEntry.tripEndDate, DateTime(2025, 6, 15));
      expect(updatedEntry.tripMemo, 'テストメモ');
    });
  });
}
