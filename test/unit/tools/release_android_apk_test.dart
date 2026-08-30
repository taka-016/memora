import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _releaseScriptPath = 'tools/ci/release_android_apk.sh';
const _appModeArgumentsScriptPath = 'tools/ci/app_mode_arguments.sh';

void main() {
  late Directory testProject;

  ProcessResult runReleaseScript(List<String> arguments) {
    final environment = Map<String, String>.from(Platform.environment);
    environment['PATH'] = '${testProject.path}/bin:${environment['PATH']}';

    return Process.runSync(
      'bash',
      ['tools/ci/release_android_apk.sh', ...arguments],
      workingDirectory: testProject.path,
      environment: environment,
    );
  }

  setUp(() {
    testProject = Directory.systemTemp.createTempSync(
      'memora_release_android_apk_test_',
    );
    Directory('${testProject.path}/tools/ci').createSync(recursive: true);
    Directory('${testProject.path}/bin').createSync(recursive: true);
    File(_releaseScriptPath)
        .copySync('${testProject.path}/tools/ci/release_android_apk.sh');
    File(_appModeArgumentsScriptPath)
        .copySync('${testProject.path}/tools/ci/app_mode_arguments.sh');
    File('${testProject.path}/pubspec.yaml')
        .writeAsStringSync('version: 1.2.3+4\n');

    final flutterStub = File('${testProject.path}/bin/flutter');
    flutterStub.writeAsStringSync('''#!/usr/bin/env bash
set -e
mkdir -p build/app/outputs/flutter-apk
touch build/app/outputs/flutter-apk/app-release.apk
printf '%s\\n' "\$@" > flutter_arguments.txt
''');
    Process.runSync('chmod', ['+x', flutterStub.path]);
  });

  tearDown(() {
    testProject.deleteSync(recursive: true);
  });

  test('指定モードをログと成果物名で確認できる', () {
    final result = runReleaseScript(['--dart-define=MEMORA_APP_MODE=offline']);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(result.stdout, contains('MEMORA_APP_MODE=offline'));
    expect(
      File(
        '${testProject.path}/build/app/outputs/flutter-apk/'
        'memora-1.2.3-offline.apk',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('${testProject.path}/flutter_arguments.txt').readAsStringSync(),
      contains('--dart-define=MEMORA_APP_MODE=offline'),
    );
  });

  test('未指定時はautoをログと成果物名へ使用する', () {
    final result = runReleaseScript([]);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(result.stdout, contains('MEMORA_APP_MODE=auto'));
    expect(
      File(
        '${testProject.path}/build/app/outputs/flutter-apk/'
        'memora-1.2.3-auto.apk',
      ).existsSync(),
      isTrue,
    );
  });

  test('不明なモードはビルド前に設定誤りとして終了する', () {
    final result = runReleaseScript(['--dart-define=MEMORA_APP_MODE=invalid']);

    expect(result.exitCode, isNot(0));
    expect(result.stderr, contains('MEMORA_APP_MODE'));
    expect(
      File('${testProject.path}/flutter_arguments.txt').existsSync(),
      isFalse,
    );
  });
}
