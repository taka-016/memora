import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/transactions/write_transaction.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/repositories/firestore_write_context.dart';
import 'package:memora/infrastructure/repositories/trip/firestore_trip_entry_repository.dart';

class FirestoreWriteTransaction implements WriteTransaction {
  FirestoreWriteTransaction({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<T> run<T>(Future<T> Function(WriteTransactionScope scope) action) {
    return _firestore.runTransaction<T>((transaction) async {
      final writeContext = FirestoreTransactionWriteContext(
        firestore: _firestore,
        transaction: transaction,
      );
      final scope = FirestoreWriteTransactionScope(
        firestore: _firestore,
        writeContext: writeContext,
      );
      return action(scope);
    });
  }
}

class FirestoreWriteTransactionScope implements WriteTransactionScope {
  FirestoreWriteTransactionScope({
    required this._firestore,
    required this._writeContext,
  });

  final FirebaseFirestore _firestore;
  final FirestoreWriteContext _writeContext;

  @override
  R repository<R extends Object>() {
    if (R == TripEntryRepository) {
      return FirestoreTripEntryRepository(
            firestore: _firestore,
            writeContext: _writeContext,
          )
          as R;
    }
    throw ArgumentError('Unsupported repository type: $R');
  }
}
