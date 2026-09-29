import 'package:memora/core/time/app_clock.dart';

class SystemAppClock implements AppClock {
  const SystemAppClock();
  @override
  Future<void> sync() async {}
  @override
  DateTime now() => DateTime.now();
}
