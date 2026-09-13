abstract interface class ReadTransaction {
  Future<T> execute<T>(Future<T> Function() action);

  Future<void> executeAndPublish<T>({
    required Future<T> Function() read,
    required Future<void> Function(T value) publish,
  });
}
