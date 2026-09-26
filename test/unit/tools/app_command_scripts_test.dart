import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPaths = ['run.sh', 'build.sh', 'release.sh', 'test.sh'];
const _appModeArgumentsScriptPath = 'tools/ci/app_mode_arguments.sh';
const _releaseScriptPath = 'tools/ci/release_android_apk.sh';

void main() {
  late Directory testProject;
  late File commandLog;

  ProcessResult runScript(String script, List<String> arguments) {
    final environment = Map<String, String>.from(Platform.environment);
    environment['PATH'] = '${testProject.path}/bin:${environment['PATH']}';
    environment['MEMORA_TEST_COMMAND_LOG'] = commandLog.path;

    return Process.runSync(
      'bash',
      [script, ...arguments],
      workingDirectory: testProject.path,
      environment: environment,
    );
  }

  setUp(() {
    testProject = Directory.systemTemp.createTempSync(
      'memora_app_command_scripts_test_',
    );
    Directory('${testProject.path}/bin').createSync(recursive: true);
    Directory('${testProject.path}/tools/ci').createSync(recursive: true);
    for (final scriptPath in _scriptPaths) {
      File(scriptPath).copySync('${testProject.path}/$scriptPath');
    }
    File(_appModeArgumentsScriptPath)
        .copySync('${testProject.path}/tools/ci/app_mode_arguments.sh');
    File(_releaseScriptPath)
        .copySync('${testProject.path}/tools/ci/release_android_apk.sh');
    File('${testProject.path}/pubspec.yaml')
        .writeAsStringSync('version: 1.2.3+4\n');
    commandLog = File('${testProject.path}/commands.log');

    final flutterStub = File('${testProject.path}/bin/flutter');
    flutterStub.writeAsStringSync('''#!/usr/bin/env bash
printf '%s\\n' "\$@" > "\$MEMORA_TEST_COMMAND_LOG"
if [ "\${1:-}" = 'build' ] && [ "\${3:-}" = '--release' ]; then
  flavor=''
  previous=''
  for argument in "\$@"; do
    if [ "\$previous" = '--flavor' ]; then
      flavor="\$argument"
      previous=''
    elif [ "\$argument" = '--flavor' ]; then
      previous='--flavor'
    fi
  done
  mkdir -p build/app/outputs/flutter-apk
  touch "build/app/outputs/flutter-apk/app-\${flavor}-release.apk"
fi
''');
    Process.runSync('chmod', ['+x', flutterStub.path]);

    final dartStub = File('${testProject.path}/bin/dart');
    dartStub.writeAsStringSync('''#!/usr/bin/env bash
printf '%s\\n' "\$@" > "\$MEMORA_TEST_COMMAND_LOG"
''');
    Process.runSync('chmod', ['+x', dartStub.path]);
  });

  tearDown(() {
    testProject.deleteSync(recursive: true);
  });

  final commands = {
    'run.sh': ['run'],
    'build.sh': ['build', 'apk', '--debug'],
    'release.sh': ['build', 'apk', '--release'],
    'test.sh': ['pub', 'global', 'run', 'very_good_cli:very_good', 'test'],
  };

  for (final MapEntry(key: script, value: command) in commands.entries) {
    test('$scriptは指定したオフラインモードで対象コマンドを実行する', () {
      final result = runScript(script, ['offline']);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(
        commandLog.readAsLinesSync(),
        containsAllInOrder([
          ...command,
          if (script != 'test.sh') ...['--flavor', 'offline'],
          '--dart-define=MEMORA_APP_MODE=offline',
        ]),
      );
    });

    test('$scriptはモード未指定時にオンラインで対象コマンドを実行する', () {
      final result = runScript(script, []);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(
        commandLog.readAsLinesSync(),
        containsAllInOrder([
          ...command,
          if (script != 'test.sh') ...['--flavor', 'online'],
          '--dart-define=MEMORA_APP_MODE=online',
        ]),
      );
    });

    test('$scriptはautoをコマンド実行前に拒否する', () {
      final result = runScript(script, ['auto']);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('online、offline'));
      expect(commandLog.existsSync(), isFalse);
    });

    test('$scriptは追加引数によるモードの上書きを拒否する', () {
      final result = runScript(script, [
        'offline',
        '--dart-define=MEMORA_APP_MODE=online',
      ]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('MEMORA_APP_MODE'));
      expect(commandLog.existsSync(), isFalse);
    });

    if (script != 'test.sh') {
      test('$scriptは追加引数によるflavorの上書きを拒否する', () {
        final result = runScript(script, ['offline', '--flavor', 'online']);

        expect(result.exitCode, isNot(0));
        expect(result.stderr, contains('flavor'));
        expect(commandLog.existsSync(), isFalse);
      });
    }
  }

  test('test.shは短縮形式によるモードの上書きを拒否する', () {
    final result = runScript('test.sh', [
      'offline',
      '-DMEMORA_APP_MODE=online',
    ]);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('MEMORA_APP_MODE'));
    expect(commandLog.existsSync(), isFalse);
  });

  for (final arguments in [
    ['--DartDefines=MEMORA_APP_MODE=online'],
    ['--DartDefines', 'MEMORA_APP_MODE=online'],
  ]) {
    test('build.shは互換別名によるモードの上書きを拒否する', () {
      final result = runScript('build.sh', ['offline', ...arguments]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('MEMORA_APP_MODE'));
      expect(commandLog.existsSync(), isFalse);
    });
  }
}
