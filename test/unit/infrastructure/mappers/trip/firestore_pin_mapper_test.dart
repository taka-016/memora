import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_pin_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestorePinMapper', () {
    test('FirestoreドキュメントからPinDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'pinDoc001',
        data: {
          'pinId': 'pin001',
          'tripId': 'trip001',
          'groupId': 'group001',
          'latitude': 35.0,
          'longitude': 135.0,
          'visitStartDate': Timestamp.fromDate(DateTime(2024, 1, 1)),
        },
      );

      final dto = FirestorePinMapper.fromFirestore(doc);

      expect(dto.pinId, 'pin001');
      expect(dto.tripId, 'trip001');
      expect(dto.groupId, 'group001');
      expect(dto.latitude, 35.0);
      expect(dto.longitude, 135.0);
      expect(dto.visitStartDate, DateTime(2024, 1, 1));
    });

    test('Firestoreの欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'pinDoc002', data: {});

      final dto = FirestorePinMapper.fromFirestore(doc);

      expect(dto.pinId, '');
      expect(dto.latitude, 0.0);
      expect(dto.longitude, 0.0);
    });

    test('PinをFirestoreのMapへ変換できる', () {
      final pin = Pin(
        pinId: 'pin003',
        tripId: 'trip003',
        groupId: 'group003',
        latitude: 34.7,
        longitude: 135.5,
      );

      final map = FirestorePinMapper.toFirestore(pin);

      expect(map['pinId'], 'pin003');
      expect(map['tripId'], 'trip003');
      expect(map['groupId'], 'group003');
      expect(map['latitude'], 34.7);
      expect(map['longitude'], 135.5);
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
