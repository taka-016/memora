import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/firestore_pin_mapper.dart';

import 'firestore_pin_mapper_test.mocks.dart';

@GenerateMocks([QueryDocumentSnapshot])
void main() {
  group('PinMapper', () {
    test('FirestoreのDocumentSnapshotからPinへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('abc123');
      when(mockDoc.data()).thenReturn({
        'pinId': 'def123',
        'latitude': 35.0,
        'longitude': 139.0,
        'locationName': '東京駅',
      });
      final pin = FirestorePinMapper.fromFirestore(mockDoc);
      expect(pin.id, 'abc123');
      expect(pin.pinId, 'def123');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
      expect(pin.locationName, '東京駅');
    });
  });
}
