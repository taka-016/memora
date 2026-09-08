abstract interface class AppClock {
  Future<void> sync();

  DateTime now();
}

class FixedAppClock implements AppClock {
  const FixedAppClock(this.fixedNow);

  final DateTime fixedNow;

  @override
  Future<void> sync() async {}

  @override
  DateTime now() {
    return fixedNow;
  }
}
