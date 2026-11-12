import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _releaseScriptPath = 'scripts/app/release_android_apk.sh';
const _appModeArgumentsScriptPath = 'scripts/app/app_mode_arguments.sh';

void main() {
  late Directory testProject;

  ProcessResult runReleaseScript(List<String> arguments) {
    final environment = Map<String, String>.from(Platform.environment);
    environment['PATH'] = '${testProject.path}/bin:${environment['PATH']}';

    return Process.runSync(
      'bash',
      ['scripts/app/release_android_apk.sh', ...arguments],
      workingDirectory: testProject.path,
      environment: environment,
    );
  }

  setUp(() {
    testProject = Directory.systemTemp.createTempSync(
      'memora_release_android_apk_test_',
    );
    Directory('${testProject.path}/scripts/app').createSync(recursive: true);
    Directory('${testProject.path}/bin').createSync(recursive: true);
    File(_releaseScriptPath)
        .copySync('${testProject.path}/scripts/app/release_android_apk.sh');
    File(_appModeArgumentsScriptPath)
        .copySync('${testProject.path}/scripts/app/app_mode_arguments.sh');
    File('${testProject.path}/pubspec.yaml')
        .writeAsStringSync('version: 1.2.3+4\n');

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
  test('リリースごとに採番してビルド失敗後も番号を再利用しない', () {
    final flutter = File('${testProject.path}/bin/flutter');
    final original = flutter.readAsStringSync();
    flutter.writeAsStringSync('#!/usr/bin/env bash\nexit 1\n');
    expect(runReleaseScript([]).exitCode, isNot(0));
    flutter.writeAsStringSync(original);
    expect(runReleaseScript([]).exitCode, 0);
    expect(
      File('${testProject.path}/flutter_arguments.txt').readAsLinesSync(),
      contains('--build-number=18'),
    );
    expect(
      File('${testProject.path}/release_operations.txt').readAsLinesSync(),
      ['next', 'next'],
    );
  });
}
