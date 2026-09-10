import 'package:memora/application/transactions/write_transaction.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/repositories/trip/sqlite_trip_entry_repository.dart';

class SqliteWriteTransaction implements WriteTransaction {
  SqliteWriteTransaction(this.db);
  final OfflineDatabase db;
  @override
  Future<T> run<T>(Future<T> Function(WriteTransactionScope scope) action) async => db.transaction(() async => action(_SqliteWriteTransactionScope(db)));
}
class _SqliteWriteTransactionScope implements WriteTransactionScope {
  _SqliteWriteTransactionScope(this.db);
  final OfflineDatabase db;
  @override
  R repository<R extends Object>() {
    if (R == TripEntryRepository) return SqliteTripEntryRepository(db) as R;
    throw ArgumentError('未対応のRepositoryです: $R');
  }
}
