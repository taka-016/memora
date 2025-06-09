import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/infrastructure/mappers/firestore_pin_mapper.dart';
import '../repositories/firestore_pin_repository_test.mocks.dart';

void main() {
  group('PinMapper', () {
    test('FirestoreのDocumentSnapshotからPinへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('abc123');
      when(
        mockDoc.data(),
      ).thenReturn({'pinId': 'def123', 'latitude': 35.0, 'longitude': 139.0});
      final pin = FirestorePinMapper.fromFirestore(mockDoc);
      expect(pin.id, 'abc123');
      expect(pin.pinId, 'def123');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
    });
  });
}
