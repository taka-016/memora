import 'package:ntp/ntp.dart';
import 'package:memora/core/time/app_clock.dart';

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
