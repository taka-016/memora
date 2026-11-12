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
    File('scripts/app/run_flutter_app.sh')
        .copySync('${testProject.path}/scripts/app/run_flutter_app.sh');
    File(_appModeArgumentsScriptPath)
        .copySync('${testProject.path}/scripts/app/app_mode_arguments.sh');
    File(_releaseScriptPath)
        .copySync('${testProject.path}/scripts/app/release_android_apk.sh');
    File('${testProject.path}/pubspec.yaml')
        .writeAsStringSync('version: 1.2.3+4\n');
    commandLog = File('${testProject.path}/commands.log');

    final dartStub = File('${testProject.path}/bin/dart');
    dartStub.writeAsStringSync(r'''#!/usr/bin/env bash
set -e
printf '%s\n' "$2" >> release_operations.txt
case "$2" in
  current) echo 16 ;;
  next)
    number=16
    if [ -f build_counter.txt ]; then number="$(cat build_counter.txt)"; fi
    number=$((number + 1))
    echo "$number" > build_counter.txt
    echo "$number"
    ;;
  require-update|maintenance) printf '%s\n' "$@" > management_arguments.txt ;;
  *) exit 1 ;;
esac
''');
    Process.runSync('chmod', ['+x', dartStub.path]);
    final flutterStub = File('${testProject.path}/bin/flutter');
    flutterStub.writeAsStringSync('''#!/usr/bin/env bash
printf '%s\\n' "\$@" > "\$MEMORA_TEST_COMMAND_LOG"
printf '%s' "\${MEMORA_ONLINE_BUILD_NUMBER:-}" > flutter_build_number.txt
if [ "\${1:-}" = run ]; then
  for argument in "\$@"; do
    case "\$argument" in --build-number*) exit 64 ;; esac
  done
fi
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
  for (final script in ['run', 'build', 'release']) {
    test('$scriptはオンライン版のビルド番号を自動設定する', () {
      final result = runScript(script, []);
      expect(result.exitCode, 0, reason: result.stderr as String);
      if (script == 'run') {
        expect(
          commandLog.readAsLinesSync().any(
            (arg) => arg.startsWith('--build-number'),
          ),
          isFalse,
        );
      } else {
        expect(
          commandLog.readAsLinesSync(),
          contains('--build-number=${script == 'release' ? 17 : 16}'),
        );
      }
      expect(
        File('${testProject.path}/flutter_build_number.txt').readAsStringSync(),
        '${script == 'release' ? 17 : 16}',
      );
      expect(
        File('${testProject.path}/release_operations.txt').readAsLinesSync(),
        [script == 'release' ? 'next' : 'current'],
      );
    });
    test('$scriptはオフライン版では採番CLIを呼ばない', () {
      expect(runScript(script, ['offline']).exitCode, 0);
      expect(
        File('${testProject.path}/release_operations.txt').existsSync(),
        isFalse,
      );
    });
    for (final override in [
      ['--build-number', '99'],
      ['--build-number=99'],
    ]) {
      test('$scriptはオンラインのビルド番号の上書きを採番前に拒否する $override', () {
        final result = runScript(script, ['online', ...override]);
        expect(result.exitCode, isNot(0));
        expect(commandLog.existsSync(), isFalse);
        expect(
          File('${testProject.path}/release_operations.txt').existsSync(),
          isFalse,
        );
      });
    }
  }
  test('更新必須化とメンテナンスのjustコマンドから管理CLIへ引数を渡す', () {
    for (final args in [
      ['require-update', '16'],
      ['maintenance', 'on'],
      ['maintenance', 'off'],
    ]) {
      final result = runScript(args.first, args.sublist(1));
      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(
        File('${testProject.path}/management_arguments.txt').readAsLinesSync(),
        ['scripts/firebase/manage_app_release.dart', ...args],
      );
    }
  });
}
