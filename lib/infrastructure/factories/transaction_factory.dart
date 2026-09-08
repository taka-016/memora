import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
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
    final dbType = ref.watch(appModeProvider);
    return _createTransactionByType<T>(dbType, ref: ref);
  }

  static T _createTransactionByType<T extends Object>(
    AppMode dbType, {
    required Ref ref,
  }) {
    switch (dbType) {
      case AppMode.online:
        return _createFirestoreTransaction<T>(ref: ref);
      case AppMode.offline:
        throw const FeatureUnavailableException(
          AppFeature.localData,
          '端末内データの保存機能は現在準備中です。',
        );
    }
  }

  static T _createFirestoreTransaction<T>({required Ref ref}) {
    if (T == WriteTransaction) {
      return FirestoreWriteTransaction(
        firestore: ref.watch(firebaseFirestoreProvider),
      ) as T;
    }
    throw ArgumentError('Unknown transaction type: $T');
  }
}
