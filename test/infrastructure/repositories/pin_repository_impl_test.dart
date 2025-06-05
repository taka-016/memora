import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_verification/infrastructure/repositories/pin_repository_impl.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
import 'pin_repository_impl_test.mocks.dart';

void main() {
  group('PinRepositoryImpl', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late PinRepositoryImpl repository;
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
      repository = PinRepositoryImpl(firestore: mockFirestore);
    });

    test(
      'savePinがpins collectionにmarkerId, latitude, longitudeをaddする',
      () async {
        const markerId = 'test-marker-id';
        const latitude = 35.0;
        const longitude = 139.0;
        when(mockCollection.add(any)).thenAnswer(
          (_) async => MockDocumentReference<Map<String, dynamic>>(),
        );

        await repository.savePin(markerId, latitude, longitude);

        verify(
          mockCollection.add(
            argThat(
              allOf(
                containsPair('markerId', markerId),
                containsPair('latitude', latitude),
                containsPair('longitude', longitude),
                contains('createdAt'),
              ),
            ),
          ),
        ).called(1);
      },
    );

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

    test('deletePinがpins collectionの該当ドキュメントを削除する', () async {
      const markerId = 'test-marker-id';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(
        mockCollection.where('markerId', isEqualTo: markerId),
      ).thenReturn(mockCollection);
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('dummy_id');
      when(mockFirestore.collection('pins')).thenReturn(mockCollection);
      when(mockCollection.doc('dummy_id')).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deletePin(markerId);

      verify(mockCollection.where('markerId', isEqualTo: markerId)).called(1);
      verify(mockCollection.get()).called(1);
      verify(mockCollection.doc('dummy_id')).called(1);
      verify(mockDocRef.delete()).called(1);
    });
  });
}
