import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _configuredProject = {
  'firestore': {
    'rules': 'firestore.rules',
    'indexes': 'firestore.indexes.json',
  },
  'flutter': {'設定': '維持する'},
};
const _unconfiguredProject = {
  'firestore': {'rules': 'firestore.rules'},
  'flutter': {'設定': '維持する'},
};
const _remoteIndexes = {'indexes': [], 'fieldOverrides': []};

void main() {
  late Directory project;
  late File commands;
  late String jqPath;

  void writeExecutable(String name, String content) {
    final file = File('${project.path}/bin/$name')..writeAsStringSync(content);
    Process.runSync('/bin/chmod', ['+x', file.path]);
  }

  setUp(() {
    project = Directory.systemTemp.createTempSync('memora firebase setup ');
    Directory('${project.path}/bin').createSync();
    Directory('${project.path}/lib').createSync();
    File('setup_firebase.sh').copySync('${project.path}/setup_firebase.sh');
    File('${project.path}/lib/firebase_options.dart').writeAsStringSync('既存設定');
    File('${project.path}/firebase.json')
        .writeAsStringSync(jsonEncode(_configuredProject));
    commands = File('${project.path}/commands.log')..writeAsStringSync('');
    jqPath =
        (Process.runSync('/bin/bash', ['-c', 'command -v jq']).stdout as String)
            .trim();
    expect(jqPath, isNotEmpty, reason: '設定ファイルの更新検証にはjqが必要です');
    Link('${project.path}/bin/grep').createSync('/bin/grep');
    for (final name in [
      'firebase',
      'firebase.template',
      'dart',
      'npm',
      'jq',
      'mv',
    ]) {
      writeExecutable(name, r'''#!/bin/bash
command_name="${0##*/}"
printf '%s %s\n' "$command_name" "$*" >> "$MEMORA_TEST_COMMAND_LOG"
if [ "$command_name" = "$MEMORA_TEST_FAIL_COMMAND" ] || [ "$command_name $*" = "$MEMORA_TEST_FAIL_COMMAND" ]; then
    exit 1
fi
case "$command_name $*" in
    'npm install -g firebase-tools') /bin/cp "$MEMORA_TEST_BIN/firebase.template" "$MEMORA_TEST_BIN/firebase" ;;
    'dart pub global list')
        if [ "$MEMORA_TEST_FLUTTERFIRE_INSTALLED" = 1 ]; then echo flutterfire_cli; fi
        ;;
    'firebase projects:list')
        if [ "$MEMORA_TEST_LOGGED_IN" = 0 ]; then exit 1; fi
        ;;
    'dart pub global run flutterfire_cli:flutterfire configure')
        printf '%s' '生成された設定' > lib/firebase_options.dart
        ;;
    'firebase firestore:indexes') printf '%s\n' "$MEMORA_TEST_REMOTE_INDEXES" ;;
esac
if [ "$command_name" = jq ]; then exec "$MEMORA_TEST_JQ" "$@"; fi
if [ "$command_name" = mv ]; then exec /bin/mv "$@"; fi
''');
    }
  });

  tearDown(() => project.deleteSync(recursive: true));

  Future<ProcessResult> runSetup({
    bool firebaseInstalled = true,
    bool flutterfireInstalled = true,
    bool loggedIn = true,
    bool jqInstalled = true,
    String answer = '',
    String failCommand = '',
  }) async {
    if (!firebaseInstalled) File('${project.path}/bin/firebase').deleteSync();
    if (!jqInstalled) File('${project.path}/bin/jq').deleteSync();
    final process = await Process.start(
      '/bin/bash',
      ['setup_firebase.sh'],
      workingDirectory: project.path,
      environment: {
        ...Platform.environment,
        'PATH': '${project.path}/bin',
        'MEMORA_TEST_BIN': '${project.path}/bin',
        'MEMORA_TEST_COMMAND_LOG': commands.path,
        'MEMORA_TEST_FAIL_COMMAND': failCommand,
        'MEMORA_TEST_FLUTTERFIRE_INSTALLED': flutterfireInstalled ? '1' : '0',
        'MEMORA_TEST_LOGGED_IN': loggedIn ? '1' : '0',
        'MEMORA_TEST_JQ': jqPath,
        'MEMORA_TEST_REMOTE_INDEXES': jsonEncode(_remoteIndexes),
      },
    );
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    if (answer.isNotEmpty) process.stdin.writeln(answer);
    await process.stdin.close();
    return ProcessResult(
      process.pid,
      await process.exitCode,
      await stdout,
      await stderr,
    );
  }

  void expectSuccess(ProcessResult result) {
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stdout, contains('セットアップ完了'));
    expect(
      jsonDecode(
        File('${project.path}/firestore.indexes.json').readAsStringSync(),
      ),
      _remoteIndexes,
    );
  }

  test('設定済み環境では再インストールせず既存設定を保ってルールとインデックスを同期する', () async {
    final result = await runSetup();

    expectSuccess(result);
    expect(commands.readAsLinesSync(), [
      'dart pub global list',
      'firebase projects:list',
      'firebase use --add',
      'firebase deploy --only firestore:rules',
      'firebase deploy --only firestore:indexes',
      'firebase firestore:indexes',
    ]);
    expect(
      jsonDecode(File('${project.path}/firebase.json').readAsStringSync()),
      _configuredProject,
    );
    expect(
      File('${project.path}/lib/firebase_options.dart').readAsStringSync(),
      '既存設定',
    );
  });

  test('初回はCLI導入からログイン・設定生成・設定補完・デプロイまで完了する', () async {
    File('${project.path}/lib/firebase_options.dart').deleteSync();
    File('${project.path}/firebase.json')
        .writeAsStringSync(jsonEncode(_unconfiguredProject));

    final result = await runSetup(
      firebaseInstalled: false,
      flutterfireInstalled: false,
      loggedIn: false,
      answer: 'y',
    );

    expectSuccess(result);
    expect(commands.readAsLinesSync(), [
      'npm install -g firebase-tools',
      'dart pub global list',
      'dart pub global activate flutterfire_cli',
      'firebase projects:list',
      'firebase login --no-localhost',
      'dart pub global run flutterfire_cli:flutterfire configure',
      'jq .firestore.indexes = "firestore.indexes.json" firebase.json',
      'mv firebase.json.tmp firebase.json',
      'firebase use --add',
      'firebase deploy --only firestore:rules',
      'firebase deploy --only firestore:indexes',
      'firebase firestore:indexes',
    ]);
    expect(
      jsonDecode(File('${project.path}/firebase.json').readAsStringSync()),
      _configuredProject,
    );
    expect(
      File('${project.path}/lib/firebase_options.dart').readAsStringSync(),
      '生成された設定',
    );
  });

  test('Firebase CLIのインストールを断ると外部処理を行わず終了する', () async {
    final result = await runSetup(firebaseInstalled: false, answer: 'n');

    expect(result.exitCode, isNot(0));
    expect(commands.readAsLinesSync(), isEmpty);
    expect(result.stdout, contains('Firebase CLIをインストールしてから再実行してください'));
    expect(result.stdout, isNot(contains('セットアップ完了')));
  });

  test('インデックス設定の補完に必要なjqがなければ設定を変更せずデプロイ前に停止する', () async {
    final config = File('${project.path}/firebase.json')
      ..writeAsStringSync(jsonEncode(_unconfiguredProject));

    final result = await runSetup(jqInstalled: false);

    expect(result.exitCode, isNot(0));
    expect(jsonDecode(config.readAsStringSync()), _unconfiguredProject);
    expect(commands.readAsLinesSync(), [
      'dart pub global list',
      'firebase projects:list',
    ]);
    expect(result.stdout, contains('jqがインストールされていません'));
    expect(result.stdout, isNot(contains('セットアップ完了')));
  });

  final failures = {
    'npm install -g firebase-tools': 'Firebase CLI導入',
    'dart pub global activate flutterfire_cli': 'FlutterFire CLI導入',
    'firebase login --no-localhost': 'ログイン',
    'dart pub global run flutterfire_cli:flutterfire configure': 'Firebase設定生成',
    'jq': 'インデックス設定変換',
    'mv': 'インデックス設定置換',
    'firebase use --add': 'プロジェクト選択',
    'firebase deploy --only firestore:rules': 'ルール適用',
    'firebase deploy --only firestore:indexes': 'インデックス適用',
    'firebase firestore:indexes': 'インデックス同期',
  };
  for (final entry in failures.entries) {
    test('${entry.value}に失敗すると後続処理を行わず異常終了する', () async {
      final failCommand = entry.key;
      if (failCommand.contains(' configure')) {
        File('${project.path}/lib/firebase_options.dart').deleteSync();
      }
      if (failCommand == 'jq' || failCommand == 'mv') {
        File('${project.path}/firebase.json')
            .writeAsStringSync(jsonEncode(_unconfiguredProject));
      }
      final result = await runSetup(
        firebaseInstalled: !failCommand.startsWith('npm '),
        flutterfireInstalled: !failCommand.contains(' activate '),
        loggedIn: !failCommand.contains(' login '),
        answer: 'y',
        failCommand: failCommand,
      );

      expect(result.exitCode, isNot(0), reason: result.stdout as String);
      final lastCommand = commands.readAsLinesSync().last;
      expect(
        lastCommand,
        failCommand == 'jq' || failCommand == 'mv'
            ? startsWith('$failCommand ')
            : failCommand,
      );
      expect(result.stdout, isNot(contains('セットアップ完了')));
      if (failCommand == 'jq' || failCommand == 'mv') {
        expect(
          jsonDecode(File('${project.path}/firebase.json').readAsStringSync()),
          _unconfiguredProject,
        );
      }
    });
  }
}
