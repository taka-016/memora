import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _checkScriptPath = 'check.sh';
const _appModeArgumentsScriptPath = 'tools/ci/app_mode_arguments.sh';

void main() {
  late Directory testProject;
  late File commandLog;

  ProcessResult runCheckScript(List<String> arguments) {
    final environment = Map<String, String>.from(Platform.environment);
    environment['PATH'] = '${testProject.path}/bin:${environment['PATH']}';
    environment['MEMORA_TEST_COMMAND_LOG'] = commandLog.path;
    environment['TMPDIR'] = '${testProject.path}/tmp';

    return Process.runSync(
      'bash',
      ['check.sh', ...arguments],
      workingDirectory: testProject.path,
      environment: environment,
    );
  }

  setUp(() {
    testProject = Directory.systemTemp.createTempSync('memora_check_test_');
    Directory('${testProject.path}/bin').createSync(recursive: true);
    Directory('${testProject.path}/tmp').createSync(recursive: true);
    Directory('${testProject.path}/tools/ci').createSync(recursive: true);
    File(_checkScriptPath).copySync('${testProject.path}/check.sh');
    File(
      _appModeArgumentsScriptPath,
    ).copySync('${testProject.path}/tools/ci/app_mode_arguments.sh');
    commandLog = File('${testProject.path}/commands.log');

    for (final command in ['dart', 'flutter']) {
      final stub = File('${testProject.path}/bin/$command');
      stub.writeAsStringSync('''#!/usr/bin/env bash
printf '$command %s\\n' "\$*" >> "\$MEMORA_TEST_COMMAND_LOG"
''');
      Process.runSync('chmod', ['+x', stub.path]);
    }
  });

  tearDown(() {
    testProject.deleteSync(recursive: true);
  });

  test('モード指定をテストへ渡してログへ出力する', () {
    final result = runCheckScript(['--dart-define=MEMORA_APP_MODE=offline']);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(result.stdout, contains('MEMORA_APP_MODE=offline'));
    expect(
      commandLog.readAsStringSync(),
      contains(
        'dart pub global run very_good_cli:very_good test '
        '--dart-define=MEMORA_APP_MODE=offline',
      ),
    );
  });

  test('不明なモードは検証開始前に設定誤りとして終了する', () {
    final result = runCheckScript(['--dart-define=MEMORA_APP_MODE=invalid']);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('MEMORA_APP_MODE'));
    expect(commandLog.existsSync(), isFalse);
  });
}
