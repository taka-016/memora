import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AppClock {
  Future<DateTime> nowUtc();
}

class SystemUtcClock implements AppClock {
  const SystemUtcClock();

  @override
  Future<DateTime> nowUtc() async => DateTime.now().toUtc();
}

class FixedAppClock implements AppClock {
  FixedAppClock(DateTime fixedNow) : _fixedNow = fixedNow.toUtc();

  final DateTime _fixedNow;

  @override
  Future<DateTime> nowUtc() async => _fixedNow;
}

final appClockProvider = Provider<AppClock>((ref) {
  return const SystemUtcClock();
});

final currentTimeProvider = FutureProvider<DateTime>((ref) async {
  final clock = ref.watch(appClockProvider);
  return clock.nowUtc();
});
