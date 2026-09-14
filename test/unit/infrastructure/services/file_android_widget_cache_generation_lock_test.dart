import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/file_android_widget_cache_generation_lock.dart';

void main() {
  test('同じプロセスの別isolateが保持するロックの解放を待つ', () async {
    final directory = await Directory.systemTemp.createTemp(
      'memora-widget-generation-lock-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final events = ReceivePort();
    addTearDown(events.close);
    final firstReady = Completer<SendPort>();
    final firstEntered = Completer<void>();
    final firstDone = Completer<void>();
    final secondReady = Completer<SendPort>();
    final secondEntered = Completer<void>();
    final secondDone = Completer<void>();
    events.listen((event) {
      final message = event as Map<Object?, Object?>;
      final id = message['id'] as int;
      final state = message['state'] as String;
      if (state == 'ready') {
        (id == 1 ? firstReady : secondReady).complete(
          message['releasePort']! as SendPort,
        );
      } else if (state == 'entered') {
        (id == 1 ? firstEntered : secondEntered).complete();
      } else if (state == 'done') {
        (id == 1 ? firstDone : secondDone).complete();
      }
    });

    await Isolate.spawn(_holdLock, [1, directory.path, events.sendPort]);
    final firstRelease = await firstReady.future;
    await firstEntered.future;
    await Isolate.spawn(_holdLock, [2, directory.path, events.sendPort]);
    final secondRelease = await secondReady.future;
    final secondEnteredBeforeRelease = await Future.any([
      secondEntered.future.then((_) => true),
      Future<void>.delayed(const Duration(milliseconds: 200))
          .then((_) => false),
    ]);

    firstRelease.send(null);
    await firstDone.future;
    await secondEntered.future;
    secondRelease.send(null);
    await secondDone.future;

    expect(secondEnteredBeforeRelease, isFalse);
  });
}

Future<void> _holdLock(List<Object> arguments) async {
  final id = arguments[0] as int;
  final directoryPath = arguments[1] as String;
  final events = arguments[2] as SendPort;
  final release = ReceivePort();
  events.send({'id': id, 'state': 'ready', 'releasePort': release.sendPort});
  final lock = FileAndroidWidgetCacheGenerationLock(directoryPath);
  await lock.synchronized(() async {
    events.send({'id': id, 'state': 'entered'});
    await release.first;
  });
  release.close();
  events.send({'id': id, 'state': 'done'});
}
