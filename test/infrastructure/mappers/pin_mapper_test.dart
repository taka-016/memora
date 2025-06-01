import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_verification/infrastructure/mappers/pin_mapper.dart';
import '../repositories/pin_repository_test.mocks.dart';

void main() {
  group('PinMapper', () {
    test('FirestoreのDocumentSnapshotからPinへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('abc123');
      when(mockDoc.data()).thenReturn({'latitude': 35.0, 'longitude': 139.0});
      final pin = PinMapper.fromFirestore(mockDoc);
      expect(pin.id, 'abc123');
      expect(pin.latitude, 35.0);
      expect(pin.longitude, 139.0);
    });
  });
}
