import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntp/ntp.dart';

final appClockProvider = Provider<AppClock>((ref) {
  return NtpSynchronizedAppClock();
});

abstract interface class AppClock {
  Future<void> sync();

  DateTime now();
}

class NtpSynchronizedAppClock implements AppClock {
  NtpSynchronizedAppClock({
    Future<DateTime> Function()? fetchNtpTime,
    DateTime Function()? systemNow,
  }) : _fetchNtpTime =
           fetchNtpTime ?? (() => NTP.now(timeout: const Duration(seconds: 3))),
       _systemNow = systemNow ?? DateTime.now;

  final Future<DateTime> Function() _fetchNtpTime;
  final DateTime Function() _systemNow;
  final Stopwatch _stopwatch = Stopwatch();
  DateTime? _syncedAtUtc;

  @override
  Future<void> sync() async {
    final ntpNow = (await _fetchNtpTime()).toUtc();
    _syncedAtUtc = ntpNow;
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  DateTime now() {
    final syncedAtUtc = _syncedAtUtc;
    if (syncedAtUtc == null) {
      return _systemNow();
    }
    return syncedAtUtc.add(_stopwatch.elapsed).toLocal();
  }
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
