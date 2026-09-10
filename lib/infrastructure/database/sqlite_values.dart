class SqliteValues {
  static DateTime? date(Object? value) => value == null
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(value as int);
}
