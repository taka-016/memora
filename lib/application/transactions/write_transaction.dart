abstract class WriteTransaction {
  Future<T> run<T>(Future<T> Function(WriteTransactionScope scope) action);
}

abstract class WriteTransactionScope {
  R repository<R extends Object>();
}
