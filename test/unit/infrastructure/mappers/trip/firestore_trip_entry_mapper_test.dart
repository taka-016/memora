import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('FirestoreTripEntryMapper', () {
    test('TripEntryからFirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip001',
        groupId: 'group001',
        tripName: 'テスト旅行',
        tripStartDate: DateTime(2025, 6, 1),
        tripEndDate: DateTime(2025, 6, 10),
        tripMemo: 'テストメモ',
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group001');
      expect(data['tripName'], 'テスト旅行');
      expect(data['tripStartDate'], isA<Timestamp>());
      expect(data['tripEndDate'], isA<Timestamp>());
      expect(data['tripMemo'], 'テストメモ');
      expect(data['createdAt'], isA<FieldValue>());
    });

    test('nullableなフィールドがnullでもFirestoreのMapへ変換できる', () {
      final tripEntry = TripEntry(
        id: 'trip002',
        groupId: 'group002',
        tripStartDate: DateTime(2025, 7, 1),
        tripEndDate: DateTime(2025, 7, 5),
      );

      final data = FirestoreTripEntryMapper.toFirestore(tripEntry);

      expect(data['groupId'], 'group002');
      expect(data['tripName'], null);
      expect(data['tripStartDate'], isA<Timestamp>());
      expect(data['tripEndDate'], isA<Timestamp>());
      expect(data['tripMemo'], null);
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
