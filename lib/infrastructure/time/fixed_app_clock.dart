import 'package:memora/core/time/app_clock.dart';

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
