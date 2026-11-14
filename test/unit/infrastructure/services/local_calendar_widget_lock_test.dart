import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/local_calendar_widget_lock.dart';

Future<void> _tryLock(List<Object> args) async {
  final result = args[0] as SendPort;
  final path = args[1] as String;
  final lock = LocalCalendarWidgetLock(directory: () async => Directory(path), busyTimeout: Duration.zero);
  try {
    await lock.run('refresh', () async { result.send('取得'); });
  } catch (error) {
    result.send(error.toString());
  }
}

void main() {
  test('別isolateの更新を排他し解除後に後続処理を実行できる', () async {
    final directory = await Directory.systemTemp.createTemp('calendar-widget-lock-');
    addTearDown(() => directory.delete(recursive: true));
    final lock = LocalCalendarWidgetLock(directory: () async => directory);
    final started = Completer<void>(); final release = Completer<void>();
    final first = lock.run('refresh', () async { started.complete(); await release.future; });
    await started.future;
    final messages = ReceivePort();
    final child = await Isolate.spawn(_tryLock, [messages.sendPort, directory.path]);
    addTearDown(() { child.kill(); messages.close(); });
    expect(await messages.first, contains('database is locked'));
    release.complete(); await first;
    var executed = false;
    await lock.run('refresh', () async { executed = true; });
    expect(executed, isTrue);
  });
}
