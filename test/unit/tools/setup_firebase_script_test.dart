import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory project;
  late File commands;

  setUp(() {
    project = Directory.systemTemp.createTempSync('memora_firebase_setup_');
    Directory('${project.path}/bin').createSync();
    Directory('${project.path}/lib').createSync();
    File('setup_firebase.sh').copySync('${project.path}/setup_firebase.sh');
    File('${project.path}/lib/firebase_options.dart').writeAsStringSync('');
    File('${project.path}/firebase.json').writeAsStringSync(
      '{"firestore":{"rules":"firestore.rules","indexes":"firestore.indexes.json"}}',
    );
    commands = File('${project.path}/commands.log');
    final stubs = {
      'dart': '#!/bin/bash\necho flutterfire_cli\n',
      'firebase': r'''#!/bin/bash
printf '%s\n' "$*" >> "$MEMORA_TEST_COMMAND_LOG"
case "$*" in
  'deploy --only firestore:rules') exit "${MEMORA_TEST_RULES_EXIT_CODE:-0}" ;;
  'firestore:indexes') echo '{"indexes":[],"fieldOverrides":[]}' ;;
esac
''',
    };
    for (final entry in stubs.entries) {
      final file = File('${project.path}/bin/${entry.key}')
        ..writeAsStringSync(entry.value);
      Process.runSync('chmod', ['+x', file.path]);
    }
  });

  tearDown(() => project.deleteSync(recursive: true));

  ProcessResult runSetup({int rulesExitCode = 0}) => Process.runSync(
    'bash',
    ['setup_firebase.sh'],
    workingDirectory: project.path,
    environment: {
      ...Platform.environment,
      'PATH': '${project.path}/bin:${Platform.environment['PATH']}',
      'MEMORA_TEST_COMMAND_LOG': commands.path,
      'MEMORA_TEST_RULES_EXIT_CODE': '$rulesExitCode',
    },
  );

  test('選択したプロジェクトへルールをデプロイしてからインデックスを同期する', () {
    final result = runSetup();

    expect(result.exitCode, 0, reason: result.stderr as String);
    expect(commands.readAsLinesSync(), [
      'projects:list',
      'use --add',
      'deploy --only firestore:rules',
      'deploy --only firestore:indexes',
      'firestore:indexes',
    ]);
    expect(result.stdout, contains('セットアップ完了'));
  });

  test('ルールのデプロイ失敗時は後続処理を行わず失敗を伝える', () {
    final result = runSetup(rulesExitCode: 1);

    expect(result.exitCode, isNot(0));
    expect(commands.readAsLinesSync(), [
      'projects:list',
      'use --add',
      'deploy --only firestore:rules',
    ]);
    expect(result.stdout, contains('ルールデプロイに失敗しました'));
    expect(result.stdout, isNot(contains('セットアップ完了')));
  });
}
