import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('実行中の親へのTERMで待機を中断し子プロセスも回収する', () async {
    final directory = await Directory.systemTemp.createTemp('memora-read-process-');
    final script = File('${directory.path}/test.sh');
    final childFile = File('${directory.path}/child');
    await script.writeAsString('''
set -euo pipefail
source scripts/test/firestore_reads/process.sh
read_regression_active_pid=''
cleanup() {
  status=\$?
  trap - EXIT TERM
  read_regression_stop "\$read_regression_active_pid"
  exit "\$status"
}
trap cleanup EXIT
trap 'exit 143' TERM
read_regression_run bash -c 'echo \$\$ > "\$1"; echo ready; exec sleep 30' _ "\$1"
''');
    final process = await Process.start('bash', [script.path, childFile.path]);
    addTearDown(() async {
      process.kill(ProcessSignal.sigkill);
      if (await childFile.exists()) {
        final pid = (await childFile.readAsString()).trim();
        await Process.run('kill', ['-KILL', '--', '-$pid']);
      }
      await directory.delete(recursive: true);
    });
    final ready = await process.stdout.transform(utf8.decoder).transform(const LineSplitter()).first.timeout(const Duration(seconds: 5));
    expect(ready, 'ready');
    final child = (await childFile.readAsString()).trim();
    expect(process.kill(ProcessSignal.sigterm), isTrue);
    expect(await process.exitCode.timeout(const Duration(seconds: 3)), 143);
    expect((await Process.run('kill', ['-0', child])).exitCode, isNot(0));
  });
}
