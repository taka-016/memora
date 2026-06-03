import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/transactions/write_transaction.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_location_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';
import 'package:memora/infrastructure/transactions/firestore_write_transaction.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  Transaction,
  CollectionReference,
  DocumentReference,
])
import 'firestore_trip_write_unit_of_work_test.mocks.dart';

void main() {
  group('FirestoreWriteTransaction', () {
    test('同じFirestore transactionを使う既存リポジトリを型指定で取得できる', () async {
      final firestore = MockFirebaseFirestore();
      final transaction = MockTransaction();
      final writeTransaction = FirestoreWriteTransaction(firestore: firestore);

      when(
        firestore.runTransaction<void>(
          any,
          timeout: anyNamed('timeout'),
          maxAttempts: anyNamed('maxAttempts'),
        ),
      ).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments.first
                as Future<void> Function(Transaction);
        await handler(transaction);
      });

      await writeTransaction.run<void>((scope) async {
        expect(scope, isA<WriteTransactionScope>());
        final tripEntryRepository = scope.repository<TripEntryRepository>();
        final locationRepository = scope.repository<LocationRepository>();
        expect(tripEntryRepository, isA<TripEntryRepository>());
        expect(locationRepository, isA<LocationRepository>());
        expect(
          tripEntryRepository,
          isA<FirestoreTripEntryRepository>(),
        );
        expect(
          locationRepository,
          isA<FirestoreLocationRepository>(),
        );
      });

      verify(firestore.runTransaction<void>(any)).called(1);
    });

    test('トランザクション内のリポジトリ書き込みは同じFirestore transactionへ積む', () async {
      final firestore = MockFirebaseFirestore();
      final transaction = MockTransaction();
      final tripEntries = MockCollectionReference<Map<String, dynamic>>();
      final locations = MockCollectionReference<Map<String, dynamic>>();
      final tripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final locationDocRef = MockDocumentReference<Map<String, dynamic>>();
      final writeTransaction = FirestoreWriteTransaction(firestore: firestore);

      when(
        firestore.runTransaction<String>(
          any,
          timeout: anyNamed('timeout'),
          maxAttempts: anyNamed('maxAttempts'),
        ),
      ).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments.first
                as Future<String> Function(Transaction);
        return handler(transaction);
      });
      when(firestore.collection('trip_entries')).thenReturn(tripEntries);
      when(firestore.collection('locations')).thenReturn(locations);
      when(tripEntries.doc()).thenReturn(tripDocRef);
      when(tripDocRef.id).thenReturn('generated-trip-id');
      when(locations.doc('location-1')).thenReturn(locationDocRef);
      when(
        transaction.set<Map<String, dynamic>>(any, any),
      ).thenReturn(transaction);

      final result = await writeTransaction.run((scope) async {
        final tripEntryRepository = scope.repository<TripEntryRepository>();
        final locationRepository = scope.repository<LocationRepository>();
        final tripId = await tripEntryRepository.saveTripEntry(
          TripEntry(id: '', groupId: 'group-1', year: 2024),
        );
        await locationRepository.saveLocation(
          Location(
            id: 'location-1',
            tripId: tripId,
            groupId: 'group-1',
            name: '東京駅',
            latitude: 35.681236,
            longitude: 139.767125,
          ),
        );
        return tripId;
      });

      expect(result, 'generated-trip-id');
      verify(transaction.set(tripDocRef, any)).called(1);
      verify(
        transaction.set(
          locationDocRef,
          argThat(
            allOf([
              containsPair('tripId', 'generated-trip-id'),
              containsPair('name', '東京駅'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verifyNever(firestore.batch());
      verifyNever(locations.add(any));
    });
  });
}
