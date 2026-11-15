import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/startup_trace.dart';

import '../../helpers/test_exception.dart';

void main() {
  test('処理が完了するまで開始だけを記録し完了後に所要時間を記録する', () async {
    final messages = <String>[];
    final trace = StartupTrace(write: messages.add);
    final pending = Completer<int>();
    trace.start();

    final result = trace.measure('初期化', () => pending.future);
    expect(messages.last, contains('初期化 開始'));
    expect(messages.any((message) => message.contains('初期化 完了')), isFalse);

    pending.complete(42);
    expect(await result, 42);
    expect(messages.last, matches(r'初期化 完了 所要=\d+ms 累計=\d+ms'));
  });

  test('失敗した処理は失敗として記録し元のエラーを維持する', () async {
    final messages = <String>[];
    final trace = StartupTrace(write: messages.add)..start();
    final error = TestException();

    await expectLater(
      trace.measure<void>('通信', () async => throw error),
      throwsA(same(error)),
    );

    expect(messages.last, matches(r'通信 失敗 所要=\d+ms 累計=\d+ms'));
    expect(messages.any((message) => message.contains('通信 完了')), isFalse);
  });

  test('計測開始前と終了後は処理を実行してもログを記録しない', () async {
    final messages = <String>[];
    final trace = StartupTrace(write: messages.add);
    expect(await trace.measure('開始前', () async => 1), 1);
    expect(messages, isEmpty);

    trace.start();
    trace.finish();
    final recorded = List<String>.of(messages);
    expect(await trace.measure('終了後', () async => 2), 2);
    trace.mark('終了後');
    expect(messages, recorded);
  });
}
