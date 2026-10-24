import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _appModeArgumentsScriptPath = 'scripts/app/app_mode_arguments.sh';
const _releaseScriptPath = 'scripts/app/release_android_apk.sh';

void main() {
  late Directory testProject;
  late File commandLog;

  ProcessResult runScript(String script, List<String> arguments) {
    final environment = Map<String, String>.from(Platform.environment);
    environment['PATH'] = '${testProject.path}/bin:${environment['PATH']}';
    environment['MEMORA_TEST_COMMAND_LOG'] = commandLog.path;

    return Process.runSync(
      'just',
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
    Directory('${testProject.path}/scripts/app').createSync(recursive: true);
    File('justfile').copySync('${testProject.path}/justfile');
    File(_appModeArgumentsScriptPath)
        .copySync('${testProject.path}/scripts/app/app_mode_arguments.sh');
    File(_releaseScriptPath)
        .copySync('${testProject.path}/scripts/app/release_android_apk.sh');
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
  });

  tearDown(() {
    testProject.deleteSync(recursive: true);
  });

  final commands = {
    'run': ['run'],
    'build': ['build', 'apk', '--debug'],
    'release': ['build', 'apk', '--release'],
  };

  for (final MapEntry(key: script, value: command) in commands.entries) {
    test('$scriptは空白やシェルの特殊文字を含む追加引数をそのまま渡す', () {
      final arguments = ['--device-id', r'端末 $(echo 実行しない) "引用"; *'];

      final result = runScript(script, ['offline', ...arguments]);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(commandLog.readAsLinesSync(), containsAllInOrder(arguments));
    });

    test('$scriptは指定したオフラインモードで対象コマンドを実行する', () {
      final result = runScript(script, ['offline']);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(
        commandLog.readAsLinesSync(),
        containsAllInOrder([
          ...command,
          '--flavor',
          'offline',
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
          '--flavor',
          'online',
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

    test('$scriptは追加引数によるflavorの上書きを拒否する', () {
      final result = runScript(script, ['offline', '--flavor', 'online']);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('flavor'));
      expect(commandLog.existsSync(), isFalse);
    });
  }

  test('buildは短縮形式によるモードの上書きを拒否する', () {
    final result = runScript('build', ['offline', '-DMEMORA_APP_MODE=online']);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('MEMORA_APP_MODE'));
    expect(commandLog.existsSync(), isFalse);
  });

  for (final arguments in [
    ['--DartDefines=MEMORA_APP_MODE=online'],
    ['--DartDefines', 'MEMORA_APP_MODE=online'],
  ]) {
    test('buildは互換別名によるモードの上書きを拒否する', () {
      final result = runScript('build', ['offline', ...arguments]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('MEMORA_APP_MODE'));
      expect(commandLog.existsSync(), isFalse);
    });
  }
}
