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
  Duration _offset = Duration.zero;

  Future<void> sync() async {
    final before = _systemNow().toUtc();
    final ntpNow = (await _fetchNtpTime()).toUtc();
    final after = _systemNow().toUtc();
    final midpoint = before.add(
      Duration(microseconds: after.difference(before).inMicroseconds ~/ 2),
    );
    _offset = ntpNow.difference(midpoint);
  }

  @override
  DateTime nowUtc() {
    return _systemNow().toUtc().add(_offset);
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
