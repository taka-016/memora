import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntp/ntp.dart';

final appClockProvider = Provider<AppClock>((ref) {
  return NtpSynchronizedAppClock();
});

abstract interface class AppClock {
  DateTime nowUtc();

  DateTime nowLocal();
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

  Future<void> sync() async {
    final ntpNow = (await _fetchNtpTime()).toUtc();
    _syncedAtUtc = ntpNow;
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  DateTime nowUtc() {
    final syncedAtUtc = _syncedAtUtc;
    if (syncedAtUtc == null) {
      return _systemNow().toUtc();
    }
    return syncedAtUtc.add(_stopwatch.elapsed);
  }

  @override
  DateTime nowLocal() {
    return nowUtc().toLocal();
  }
}

class FixedAppClock implements AppClock {
  const FixedAppClock(this.fixedNowUtc);

  final DateTime fixedNowUtc;

  @override
  DateTime nowUtc() {
    return fixedNowUtc.toUtc();
  }

  @override
  DateTime nowLocal() {
    return nowUtc().toLocal();
  }
}
