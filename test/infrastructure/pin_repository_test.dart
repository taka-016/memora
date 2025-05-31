import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_verification/infrastructure/pin_repository.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'pin_repository_test.mocks.dart';

void main() {
  group('PinRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late PinRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc2;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('pins')).thenReturn(mockCollection);
      repository = PinRepository(firestore: mockFirestore);
    });

    test('savePinがpins collectionにaddする', () async {
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

    test('getPinsがFirestoreからPinのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.id).thenReturn('id1');
      when(mockDoc1.data()).thenReturn({'latitude': 35.0, 'longitude': 139.0});
      when(mockDoc2.id).thenReturn('id2');
      when(mockDoc2.data()).thenReturn({'latitude': 36.0, 'longitude': 140.0});

      final result = await repository.getPins();

      expect(result.length, 2);
      expect(result[0].id, 'id1');
      expect(result[0].latitude, 35.0);
      expect(result[0].longitude, 139.0);
      expect(result[1].id, 'id2');
      expect(result[1].latitude, 36.0);
      expect(result[1].longitude, 140.0);
    });

    test('getPinsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getPins();

      expect(result, isEmpty);
    });
  });
}
