import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_entry.dart';

void main() {
  group('TripEntry', () {
    test('インスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
      );
      expect(entry.id, 'abc123');
      expect(entry.tripName, 'テスト旅行');
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.tripMemo, 'テストメモ');
    });

    test('nullableなフィールドがnullの場合でもインスタンス生成が正しく行われる', () {
      final entry = TripEntry(id: 'abc123', tripStartDate: DateTime(2025, 6, 1), tripEndDate: DateTime(2025, 6, 10));
      expect(entry.id, 'abc123');
      expect(entry.tripName, null);
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.tripMemo, null);
    });
  });
}
