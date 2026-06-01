import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_location_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  WriteBatch,
])
import 'firestore_location_repository_test.mocks.dart';

void main() {
  group('FirestoreLocationRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockLocationsCollection;
    late FirestoreLocationRepository repository;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockLocationsCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('locations'),
      ).thenReturn(mockLocationsCollection);
      repository = FirestoreLocationRepository(firestore: mockFirestore);
    });

    test('saveLocationはlocationsへ新規追加する', () async {
      final location = Location(
        id: '',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(
        mockLocationsCollection.add(any),
      ).thenAnswer((_) async => mockDocRef);

      await repository.saveLocation(location);

      verify(
        mockLocationsCollection.add(
          argThat(
            allOf([
              containsPair('tripId', 'trip-1'),
              containsPair('groupId', 'group-1'),
              containsPair('name', '東京駅'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verifyNever(mockLocationsCollection.doc(any));
    });

    test('saveLocationはidが指定されている場合に指定idのドキュメントへ保存する', () async {
      final location = Location(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockLocationsCollection.doc('location-1')).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      await repository.saveLocation(location);

      verify(mockLocationsCollection.doc('location-1')).called(1);
      verify(
        mockDocRef.set(
          argThat(
            allOf([
              containsPair('tripId', 'trip-1'),
              containsPair('groupId', 'group-1'),
              containsPair('name', '東京駅'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verifyNever(mockLocationsCollection.add(any));
    });

    test('updateLocationは既存ドキュメントをupdateしcreatedAtを更新しない', () async {
      final location = Location(
        id: 'location-1',
        tripId: 'trip-1',
        groupId: 'group-1',
        name: '東京駅',
        latitude: 35.681236,
        longitude: 139.767125,
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockLocationsCollection.doc('location-1')).thenReturn(mockDocRef);
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      await repository.updateLocation(location);

      verify(
        mockDocRef.update(
          argThat(
            allOf([
              containsPair('tripId', 'trip-1'),
              containsPair('groupId', 'group-1'),
              containsPair('name', '東京駅'),
              isNot(contains('createdAt')),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verifyNever(mockDocRef.set(any));
    });
  });
}
