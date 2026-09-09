abstract interface class AppClock {
  Future<void> sync();

  DateTime now();
}
