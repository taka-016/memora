import 'package:memora/application/transactions/write_transaction.dart';

class GuardedWriteTransaction implements WriteTransaction {
  const GuardedWriteTransaction(this._delegate, this._ensureAvailable);

  final WriteTransaction _delegate;
  final Future<void> Function() _ensureAvailable;

  @override
  Future<T> run<T>(
    Future<T> Function(WriteTransactionScope scope) action,
  ) async {
    await _ensureAvailable();
    return await _delegate.run(action);
  }
}
