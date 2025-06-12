import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip_entry.dart';

void main() {
  group('TripEntry', () {
    test('インスタンス生成が正しく行われる', () {
      final entry = TripEntry(
        id: 'abc123',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        pinId: 'pin001',
        tripMemo: 'テストメモ',
      );
      expect(entry.id, 'abc123');
      expect(entry.tripStartDate, DateTime(2025, 6, 1));
      expect(entry.tripEndDate, DateTime(2025, 6, 10));
      expect(entry.pinId, 'pin001');
      expect(entry.tripMemo, 'テストメモ');
    });
  });
}
