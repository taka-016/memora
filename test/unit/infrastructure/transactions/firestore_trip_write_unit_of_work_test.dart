import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_location_repository.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';
import 'package:memora/infrastructure/transactions/firestore_trip_write_unit_of_work.dart';
import 'package:mockito/mockito.dart';

import 'firestore_trip_location_write_transaction_test.mocks.dart';

void main() {
  group('FirestoreTripWriteUnitOfWork', () {
    test('同じFirestore transactionを使う既存リポジトリを渡す', () async {
      final firestore = MockFirebaseFirestore();
      final transaction = MockTransaction();
      final unitOfWork = FirestoreTripWriteUnitOfWork(firestore: firestore);

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

      await unitOfWork.run<void>((repositories) async {
        expect(repositories, isA<TripWriteRepositories>());
        expect(repositories.tripEntryRepository, isA<TripEntryRepository>());
        expect(repositories.locationRepository, isA<LocationRepository>());
        expect(
          repositories.tripEntryRepository,
          isA<FirestoreTripEntryRepository>(),
        );
        expect(
          repositories.locationRepository,
          isA<FirestoreLocationRepository>(),
        );
      });

      verify(firestore.runTransaction<void>(any)).called(1);
    });

    test('UnitOfWork内のリポジトリ書き込みは同じFirestore transactionへ積む', () async {
      final firestore = MockFirebaseFirestore();
      final transaction = MockTransaction();
      final tripEntries = MockCollectionReference<Map<String, dynamic>>();
      final locations = MockCollectionReference<Map<String, dynamic>>();
      final tripDocRef = MockDocumentReference<Map<String, dynamic>>();
      final locationDocRef = MockDocumentReference<Map<String, dynamic>>();
      final unitOfWork = FirestoreTripWriteUnitOfWork(firestore: firestore);

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

      final result = await unitOfWork.run((repositories) async {
        final tripId = await repositories.tripEntryRepository.saveTripEntry(
          TripEntry(id: '', groupId: 'group-1', year: 2024),
        );
        await repositories.locationRepository.saveLocation(
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
