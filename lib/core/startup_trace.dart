import 'package:flutter/foundation.dart';

final startupTrace = StartupTrace(
  write: (message) {
    if (kDebugMode) debugPrint(message);
  },
);

class StartupTrace {
  StartupTrace({required void Function(String) write}) : _write = write;

  final void Function(String) _write;
  final Stopwatch _total = Stopwatch();

  void start() {
    _total
      ..reset()
      ..start();
    mark('計測開始');
  }

  void mark(String label) {
    if (_total.isRunning) {
      _write('起動計測: $label 累計=${_total.elapsedMilliseconds}ms');
    }
  }

  Future<T> measure<T>(String label, Future<T> Function() action) async {
    if (!_total.isRunning) return await action();
    final elapsed = Stopwatch()..start();
    mark('$label 開始');
    var succeeded = false;
    try {
      final result = await action();
      succeeded = true;
      return result;
    } finally {
      mark(
        '$label ${succeeded ? '完了' : '失敗'} '
        '所要=${elapsed.elapsedMilliseconds}ms',
      );
    }
  }

  void finish() {
    mark('最初のフレーム描画完了');
    _total.stop();
  }
}
