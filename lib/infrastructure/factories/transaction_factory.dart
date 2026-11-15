import 'package:memora/application/decorators/guarded_write_transaction.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/transactions/sqlite_write_transaction.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/transactions/write_transaction.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/transactions/firestore_write_transaction.dart';

final writeTransactionProvider = Provider<WriteTransaction>((ref) {
  return TransactionFactory.create<WriteTransaction>(ref: ref);
});

class TransactionFactory {
  static T create<T extends Object>({required Ref ref}) {
    if (T != WriteTransaction) {
      throw ArgumentError('Unknown transaction type: $T');
    }
    final WriteTransaction transaction = switch (ref.watch(appModeProvider)) {
      AppMode.online => FirestoreWriteTransaction(
        firestore: ref.watch(firebaseFirestoreProvider),
      ),
      AppMode.offline => SqliteWriteTransaction(
        ref.watch(offlineDatabaseProvider),
      ),
    };
    return GuardedWriteTransaction(
      transaction,
      ref.watch(ensureAppAvailableForMutationProvider),
    ) as T;
  }
}
