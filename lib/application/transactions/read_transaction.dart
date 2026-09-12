typedef ReadTransaction = Future<T> Function<T>(Future<T> Function() action);
