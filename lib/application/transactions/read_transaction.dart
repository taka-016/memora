abstract interface class ReadTransaction {
  Future<T> execute<T>(Future<T> Function() action);
}
