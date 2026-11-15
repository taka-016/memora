import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/app_services.dart';
import 'package:memora/composition_root/app_composition_root.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/logging/device_app_log.dart';

import '../../helpers/test_exception.dart';

class _Clock implements AppClock {
  final ready = Completer<void>();
  bool started = false;
  @override
  Future<void> sync() { started = true; return ready.future; }
  @override
  DateTime now() => DateTime(2026, 11, 15);
}

class _Services implements AppServices {
  final ready = Completer<void>();
  bool started = false;
  @override
  final _Clock clock = _Clock();
  @override
  AppLog get log => const SilentAppLog();
  @override
  Future<void> initialize() { started = true; return ready.future; }
}

class _Root extends AppCompositionRoot {
  _Root(this.services) : super(AppMode.online);
  @override
  final _Services services;
}

void main() {
  for (final clockFails in [false, true]) {
    test('SDK初期化と時刻同期を同時に開始し同期失敗$clockFailsでも両方の完了を待つ', () async {
      final services = _Services();
      final root = _Root(services);
      var complete = false;
      final initialization = root.initialize();
      final observed = () async { await initialization; complete = true; }();
      expect(services.started, isTrue);
      expect(services.clock.started, isTrue);
      if (clockFails) {
        services.clock.ready.completeError(TestException('時刻同期失敗'));
      } else {
        services.clock.ready.complete();
      }
      await Future<void>.value();
      expect(complete, isFalse);
      services.ready.complete();
      await observed;
      expect(complete, isTrue);
    });
  }
}
