import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart'
    as firestore_mapper;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firestore_itinerary_item_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreItineraryItemMapper', () {
    test('FirestoreドキュメントからItineraryItemDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('item001');
      when(doc.data()).thenReturn({
        'tripId': 'trip001',
        'orderIndex': 0,
        'name': '朝食',
        'startDateTime': Timestamp.fromDate(DateTime(2024, 1, 2, 8)),
        'endDateTime': Timestamp.fromDate(DateTime(2024, 1, 2, 9)),
        'memo': 'ホテルで朝食',
      });

      final dto = firestore_mapper.FirestoreItineraryItemMapper.fromFirestore(
        doc,
      );

      expect(dto.id, 'item001');
      expect(dto.tripId, 'trip001');
      expect(dto.orderIndex, 0);
      expect(dto.name, '朝食');
      expect(dto.startDateTime, DateTime(2024, 1, 2, 8));
      expect(dto.endDateTime, DateTime(2024, 1, 2, 9));
      expect(dto.memo, 'ホテルで朝食');
    });

    test('ItineraryItemエンティティをFirestore作成用マップへ変換できる', () {
      final item = ItineraryItem(
        id: 'item001',
        tripId: 'trip001',
        orderIndex: 0,
        name: '朝食',
        startDateTime: DateTime(2024, 1, 2, 8),
        endDateTime: DateTime(2024, 1, 2, 9),
        memo: 'ホテルで朝食',
      );

      final map = firestore_mapper.FirestoreItineraryItemMapper
          .toCreateFirestore(item);

      expect(map['tripId'], 'trip001');
      expect(map['orderIndex'], 0);
      expect(map['name'], '朝食');
      expect(map['startDateTime'], Timestamp.fromDate(DateTime(2024, 1, 2, 8)));
      expect(map['endDateTime'], Timestamp.fromDate(DateTime(2024, 1, 2, 9)));
      expect(map['memo'], 'ホテルで朝食');
      expect(map, contains('createdAt'));
      expect(map, contains('updatedAt'));
    });
  });
}
