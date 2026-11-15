import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/composition_root/startup_background_registration.dart';

import '../../helpers/test_exception.dart';

void main() {
  late Set<String> registered;
  late List<String> calls;
  late List<String> errors;
  late Completer<void> initialize;
  late Completer<void> delay;
  late Duration interval;
  late StartupBackgroundRegistration registration;
  Future<void> Function()? widgetRegistration;

  setUp(() {
    registered = {};
    calls = [];
    errors = [];
    initialize = Completer<void>();
    delay = Completer<void>();
    interval = const Duration(minutes: 30);
    widgetRegistration = null;
    registration = StartupBackgroundRegistration(
      loadRegistered: (task) async => registered.contains(task),
      markRegistered: (task) async => registered.add(task),
      initialize: () {
        calls.add('初期化');
        return initialize.future;
      },
      registerNotifications: () async => calls.add('通知'),
      loadWidgetInterval: () async => interval,
      registerWidget: (frequency) async {
        calls.add('ウィジェット:${frequency.inMinutes}');
        await widgetRegistration?.call();
      },
    );
  });

  testWidgets('未登録は表示後の遅延を待たず初期化後に登録し成功した機能を記録する', (tester) async {
    final running = registration.start(
      waitBeforeReregistration: () => delay.future,
      onError: errors.add,
    );
    await tester.pump();
    expect(calls, ['初期化']);
    initialize.complete();
    await tester.pump();
    await running;
    expect(calls, containsAll(['通知', 'ウィジェット:30']));
    expect(registered, {'notifications', 'widget'});
    expect(errors, isEmpty);
  });

  testWidgets('登録済みは初回画面表示後の遅延まで待ち最新の設定で再登録する', (tester) async {
    registered.addAll(['notifications', 'widget']);
    final running = registration.start(
      waitBeforeReregistration: () => delay.future,
      onError: errors.add,
    );
    await tester.pump();
    expect(calls, isEmpty);
    interval = const Duration(minutes: 60);
    initialize.complete();
    delay.complete();
    await tester.pump();
    await running;
    expect(calls, ['初期化', '通知', 'ウィジェット:60']);
  });

  testWidgets('一方が失敗しても他方は登録し失敗機能は次回起動で遅延せず再試行する', (tester) async {
    widgetRegistration = () async => throw TestException('ウィジェット登録失敗');
    initialize.complete();
    await registration.start(
      waitBeforeReregistration: () => delay.future,
      onError: errors.add,
    );
    expect(registered, {'notifications'});
    expect(errors.single, contains('ウィジェット'));
    widgetRegistration = null;
    calls.clear();
    final retry = registration.start(
      waitBeforeReregistration: () => delay.future,
      onError: errors.add,
    );
    await tester.pump();
    expect(calls, ['ウィジェット:30']);
    expect(registered, {'notifications', 'widget'});
    delay.complete();
    await tester.pump();
    await retry;
  });

  testWidgets('設定変更の登録は進行中の起動登録の後で実行し古い間隔を最後に残さない', (tester) async {
    initialize.complete();
    final first = Completer<void>();
    widgetRegistration = () => first.future;
    final startup = registration.registerWidget();
    await tester.pump();
    expect(calls.last, 'ウィジェット:30');
    interval = const Duration(minutes: 60);
    final setting = registration.registerWidget();
    await tester.pump();
    expect(calls.where((call) => call.startsWith('ウィジェット')).length, 1);
    widgetRegistration = null;
    first.complete();
    await tester.pump();
    await startup;
    await setting;
    expect(calls.last, 'ウィジェット:60');
  });

  testWidgets('初期化失敗は両機能のエラーにして登録済みを残さず再試行できる', (tester) async {
    final running = registration.start(
      waitBeforeReregistration: () => delay.future,
      onError: errors.add,
    );
    await tester.pump();
    initialize.completeError(TestException('初期化失敗'));
    await tester.pump();
    await running;
    expect(registered, isEmpty);
    expect(errors, hasLength(2));
    expect(errors.any((message) => message.contains('通知')), isTrue);
    expect(errors.any((message) => message.contains('ウィジェット')), isTrue);
    initialize = Completer<void>()..complete();
    await registration.start(
      waitBeforeReregistration: () => delay.future,
      onError: errors.add,
    );
    expect(registered, {'notifications', 'widget'});
  });
}
