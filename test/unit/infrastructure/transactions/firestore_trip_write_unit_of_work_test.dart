import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
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
  });
}
