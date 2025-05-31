import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/infrastructure/pin_repository.dart';

@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'pin_repository_test.mocks.dart';

void main() {
  group('PinRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late PinRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('pins')).thenReturn(mockCollection);
      repository = PinRepository(firestore: mockFirestore);
    });

    test('savePin calls add on pins collection', () async {
      final position = LatLng(35.0, 139.0);
      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.savePin(position);

      verify(
        mockCollection.add(
          argThat(
            allOf(
              containsPair('latitude', position.latitude),
              containsPair('longitude', position.longitude),
            ),
          ),
        ),
      ).called(1);
    });
  });
}
