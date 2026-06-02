import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/transactions/trip_location_write_transaction.dart';
import 'package:memora/application/transactions/trip_write_unit_of_work.dart';
import 'package:memora/infrastructure/config/database_type.dart';
import 'package:memora/infrastructure/config/database_type_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/transactions/firestore_trip_location_write_transaction.dart';
import 'package:memora/infrastructure/transactions/firestore_trip_write_unit_of_work.dart';

final tripLocationWriteTransactionProvider =
    Provider<TripLocationWriteTransaction>((ref) {
      return TransactionFactory.create<TripLocationWriteTransaction>(ref: ref);
    });

final tripWriteUnitOfWorkProvider = Provider<TripWriteUnitOfWork>((ref) {
  return TransactionFactory.create<TripWriteUnitOfWork>(ref: ref);
});

class TransactionFactory {
  static T create<T extends Object>({required Ref ref}) {
    final dbType = ref.watch(databaseTypeProvider);
    return _createTransactionByType<T>(dbType, ref: ref);
  }

  static T _createTransactionByType<T extends Object>(
    DatabaseType dbType, {
    required Ref ref,
  }) {
    switch (dbType) {
      case DatabaseType.firestore:
        return _createFirestoreTransaction<T>(ref: ref);
      case DatabaseType.sqlite:
        throw UnimplementedError(
          'Supabase implementation is not yet available',
        );
    }
  }

  static T _createFirestoreTransaction<T>({required Ref ref}) {
    if (T == TripLocationWriteTransaction) {
      return FirestoreTripLocationWriteTransaction(
            firestore: ref.watch(firebaseFirestoreProvider),
          )
          as T;
    }
    if (T == TripWriteUnitOfWork) {
      return FirestoreTripWriteUnitOfWork(
            firestore: ref.watch(firebaseFirestoreProvider),
          )
          as T;
    }
    throw ArgumentError('Unknown transaction type: $T');
  }
}
