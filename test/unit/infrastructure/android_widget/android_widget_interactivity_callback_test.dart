import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/android_widget/android_widget_interactivity_callback.dart';

import '../../../helpers/test_exception.dart';

void main() {
  test('実際の自動取得が終了するまで重複を抑え日付指定と失敗後の再試行を通す', () async {
    final automatic = Uri.parse(
      'memoraWidget://calendarRefresh?date=&automatic=true',
    );
    final moved = Uri.parse('memoraWidget://calendarRefresh?date=2026-12-01');
    final manual = Uri.parse('memoraWidget://calendarRefresh?date=');
    final pending = Completer<void>();
    final received = <Uri?>[];
    final handler = AndroidWidgetInteractivityHandler((uri) async {
      received.add(uri);
      if (received.length == 1) await pending.future;
    });

    final first = handler(automatic);
    final failed = expectLater(first, throwsA(isA<TestException>()));
    await handler(automatic);
    await handler(automatic);
    await handler(moved);
    await handler(manual);
    final beforeFailure = received.toList();
    pending.completeError(TestException('自動取得の失敗'));
    await failed;
    await handler(automatic);

    expect(beforeFailure, [automatic, moved, manual]);
    expect(received, [automatic, moved, manual, automatic]);
  });
}
