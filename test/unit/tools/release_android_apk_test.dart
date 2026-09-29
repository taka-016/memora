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
flavor=''
previous=''
for argument in "\$@"; do
  if [ "\$previous" = '--flavor' ]; then
    flavor="\$argument"
    previous=''
    continue
  fi
  if [ "\$argument" = '--flavor' ]; then
    previous='--flavor'
  fi
done
touch "build/app/outputs/flutter-apk/app-\${flavor}-release.apk"
printf '%s\\n' "\$@" > flutter_arguments.txt
''');
    Process.runSync('chmod', ['+x', flutterStub.path]);
  });

  tearDown(() {
    testProject.deleteSync(recursive: true);
  });

  test('指定モードをログと成果物名で確認できる', () {
    final result = runReleaseScript(['offline']);

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
      allOf(
        contains('--flavor\noffline'),
        contains('--dart-define=MEMORA_APP_MODE=offline'),
      ),
    );
  });

  test('オンライン版を既存モードの成果物として生成する', () {
    final result = runReleaseScript(['online']);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(result.stdout, contains('MEMORA_APP_MODE=online'));
    expect(
      File(
        '${testProject.path}/build/app/outputs/flutter-apk/'
        'memora-1.2.3-online.apk',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('${testProject.path}/flutter_arguments.txt').readAsStringSync(),
      allOf(
        contains('--flavor\nonline'),
        contains('--dart-define=MEMORA_APP_MODE=online'),
      ),
    );
  });

  test('未指定時はオンライン版を生成する', () {
    final result = runReleaseScript([]);

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(result.stdout, contains('MEMORA_APP_MODE=online'));
    expect(
      File(
        '${testProject.path}/build/app/outputs/flutter-apk/'
        'memora-1.2.3-online.apk',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('${testProject.path}/flutter_arguments.txt').readAsStringSync(),
      contains('--dart-define=MEMORA_APP_MODE=online'),
    );
  });

  for (final mode in ['auto', 'invalid']) {
    test('$modeはビルド前に設定誤りとして終了する', () {
      final result = runReleaseScript([mode]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('online、offline'));
      expect(
        File('${testProject.path}/flutter_arguments.txt').existsSync(),
        isFalse,
      );
    });
  }
}
