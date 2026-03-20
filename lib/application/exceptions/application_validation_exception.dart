class ApplicationValidationException implements Exception {
  const ApplicationValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
