import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _oldKey = 'AIzaOldFirebaseKey';
const _firebaseKey = 'AIzaSelectedFirebaseKey';
const _config = {
  'project_info': {'project_id': 'test-project'},
  'client': [
    {
      'client_info': {
        'mobilesdk_app_id': 'android-app',
        'android_client_info': {'package_name': 'test.memora'},
      },
      'api_key': [
        {'current_key': 'AIzaMapsKey'},
      ],
      'oauth_client': [
        {'client_type': 1, 'client_id': 'android-client'},
        {'client_type': 3, 'client_id': 'web-client'},
      ],
    },
    {
      'client_info': {'mobilesdk_app_id': 'another-app'},
      'api_key': [
        {'current_key': 'another-key'},
      ],
    },
  ],
};
const _dartConfig =
    '''class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$_oldKey',
    appId: 'android-app',
    projectId: 'test-project',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'ios-key',
    appId: 'ios-app',
    projectId: 'test-project',
  );
}
''';

void main() {
  late Directory project;
  late File commands;
  late String dartPath;
  late String justPath;

  File file(String path) => File('${project.path}/$path');

  void executable(String name, String content) {
    final script = file('bin/$name')..writeAsStringSync(content);
    Process.runSync('/bin/chmod', ['+x', script.path]);
  }

  setUp(() {
    project = Directory.systemTemp.createTempSync('memora firebase setup ');
    for (final dir in ['bin', 'lib', 'android/app', 'scripts/firebase']) {
      Directory('${project.path}/$dir').createSync(recursive: true);
    }
    for (final name in ['setup.sh', 'set_api_key.dart']) {
      final source = File('scripts/firebase/$name');
      if (source.existsSync()) {
        source.copySync('${project.path}/scripts/firebase/$name');
      }
    }
    File('justfile').copySync('${project.path}/justfile');
    file('lib/firebase_options.dart').writeAsStringSync(_dartConfig);
    file('android/app/google-services.json')
        .writeAsStringSync(jsonEncode(_config));
    file('firebase.json').writeAsStringSync(
      jsonEncode({
        'firestore': {'rules': 'firestore.rules'},
        'flutter': {'設定': '維持する'},
      }),
    );
    file('firestore.indexes.json').writeAsStringSync('{"indexes":["既存"]}');
    commands = file('commands.log')..writeAsStringSync('');
    dartPath =
        (Process.runSync('/bin/bash', ['-c', 'command -v dart']).stdout
                as String)
            .trim();
    justPath =
        (Process.runSync('/bin/bash', ['-c', 'command -v just']).stdout
                as String)
            .trim();
    for (final name in [
      'bash',
      'dirname',
      'grep',
      'jq',
      'mv',
      'rm',
      'mktemp',
      'cat',
    ]) {
      final path =
          (Process.runSync('/bin/bash', ['-c', 'command -v $name']).stdout
                  as String)
              .trim();
      Link('${project.path}/bin/$name').createSync(path);
    }
    for (final name in ['firebase', 'dart', 'npm']) {
      executable(name, r'''#!/bin/bash
name="${0##*/}"
printf '%s %s\n' "$name" "$*" >> "$MEMORA_TEST_COMMAND_LOG"
if [[ "$name $*" == "$MEMORA_TEST_FAIL_COMMAND" ]]; then exit 1; fi
case "$name $*" in
  'dart pub global list') echo flutterfire_cli ;;
  'dart pub global run flutterfire_cli:flutterfire configure'*)
    printf '%s' "$MEMORA_TEST_DART_CONFIG" > lib/firebase_options.dart
    printf '%s' "$MEMORA_TEST_JSON_CONFIG" > android/app/google-services.json
    ;;
  'dart scripts/firebase/set_api_key.dart') exec "$MEMORA_TEST_DART" "$@" ;;
  'firebase firestore:indexes'*) printf '%s' '{"indexes":[],"fieldOverrides":[]}' ;;
esac
''');
    }
  });

  tearDown(() => project.deleteSync(recursive: true));

  Future<ProcessResult> runSetup(
    List<String> args, {
    String input = '',
    String key = _firebaseKey,
    String failCommand = '',
    bool viaJust = false,
  }) async {
    final process = await Process.start(
      viaJust ? justPath : '/bin/bash',
      viaJust
          ? ['setup-firebase', ...args]
          : ['scripts/firebase/setup.sh', ...args],
      workingDirectory: project.path,
      environment: {
        ...Platform.environment,
        'PATH': '${project.path}/bin',
        'FIREBASE_API_KEY': key,
        'MEMORA_TEST_COMMAND_LOG': commands.path,
        'MEMORA_TEST_FAIL_COMMAND': failCommand,
        'MEMORA_TEST_DART': dartPath,
        'MEMORA_TEST_DART_CONFIG': _dartConfig,
        'MEMORA_TEST_JSON_CONFIG': jsonEncode(_config),
      },
    );
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.transform(utf8.decoder).join();
    process.stdin.write(input);
    await process.stdin.close();
    return ProcessResult(
      process.pid,
      await process.exitCode,
      await stdout,
      await stderr,
    );
  }

  void success(ProcessResult result) {
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }

  void expectKeyUpdated() {
    final expected = jsonDecode(jsonEncode(_config)) as Map<String, dynamic>;
    expected['client'][0]['api_key'][0]['current_key'] = _firebaseKey;
    expect(
      jsonDecode(file('android/app/google-services.json').readAsStringSync()),
      expected,
    );
    expect(
      file('lib/firebase_options.dart').readAsStringSync(),
      _dartConfig.replaceFirst(_oldKey, _firebaseKey),
    );
  }

  test('APIキーだけの更新はCloudへ接続せずOAuthと他アプリの設定を保つ', () async {
    success(await runSetup(['api-key']));
    expectKeyUpdated();
    expect(commands.readAsLinesSync(), [
      'dart scripts/firebase/set_api_key.dart',
    ]);
  });

  test('キー未指定時は入力を受け取りキーそのものを出力しない', () async {
    final result = await runSetup(
      ['api-key'],
      key: '',
      input: '$_firebaseKey\n',
    );
    success(result);
    expectKeyUpdated();
    expect('${result.stdout}${result.stderr}', isNot(contains(_firebaseKey)));
  });

  test('設定生成では既存ファイルを更新してから指定キーへ揃えデプロイしない', () async {
    success(await runSetup(['configure']));
    expectKeyUpdated();
    expect(commands.readAsLinesSync(), [
      'firebase projects:list',
      'dart pub global list',
      'dart pub global run flutterfire_cli:flutterfire configure --platforms=android',
      'dart scripts/firebase/set_api_key.dart',
    ]);
  });

  test('引数なしではメニューからAPIキー更新だけを選択できる', () async {
    success(await runSetup([], input: '3\n'));
    expectKeyUpdated();
    expect(commands.readAsLinesSync(), [
      'dart scripts/firebase/set_api_key.dart',
    ]);
  });

  test('メニューを選択せず入力が終了した場合は処理を実行しない', () async {
    final result = await runSetup([]);
    expect(result.exitCode, isNot(0));
    expect(commands.readAsLinesSync(), isEmpty);
  });

  for (final entry in {
    'project': ['firebase use --add'],
    'rules': ['firebase deploy --only firestore:rules'],
    'indexes': ['firebase deploy --only firestore:indexes'],
    'sync-indexes': ['firebase firestore:indexes'],
  }.entries) {
    test('${entry.key}は指定したCloud処理だけを実行する', () async {
      final original = file('lib/firebase_options.dart').readAsStringSync();
      success(await runSetup([entry.key]));
      expect(commands.readAsLinesSync(), [
        'firebase projects:list',
        ...entry.value,
      ]);
      expect(file('lib/firebase_options.dart').readAsStringSync(), original);
      if (entry.key == 'indexes') {
        final config = jsonDecode(file('firebase.json').readAsStringSync());
        expect(config['firestore']['indexes'], 'firestore.indexes.json');
        expect(config['flutter'], {'設定': '維持する'});
      }
      if (entry.key == 'sync-indexes') {
        expect(jsonDecode(file('firestore.indexes.json').readAsStringSync()), {
          'indexes': [],
          'fieldOverrides': [],
        });
      }
    });
  }

  test('複数処理を順に実行しログイン確認は一度だけ行う', () async {
    success(await runSetup(['rules', 'indexes']));
    expect(commands.readAsLinesSync(), [
      'firebase projects:list',
      'firebase deploy --only firestore:rules',
      'firebase deploy --only firestore:indexes',
    ]);
  });

  test('全処理ではプロジェクト選択後に設定生成・キー更新・デプロイ・取得を行う', () async {
    success(await runSetup(['all']));
    expectKeyUpdated();
    expect(commands.readAsLinesSync(), [
      'firebase projects:list',
      'firebase use --add',
      'dart pub global list',
      'dart pub global run flutterfire_cli:flutterfire configure --platforms=android',
      'dart scripts/firebase/set_api_key.dart',
      'firebase deploy --only firestore:rules',
      'firebase deploy --only firestore:indexes',
      'firebase firestore:indexes',
    ]);
  });

  test('不明な処理が後ろにあっても先行する処理を実行しない', () async {
    final result = await runSetup(['rules', 'unknown']);
    expect(result.exitCode, isNot(0));
    expect(commands.readAsLinesSync(), isEmpty);
  });

  test('JSONとDartの対象アプリが違う場合は両ファイルを変更しない', () async {
    file('lib/firebase_options.dart').writeAsStringSync(
      _dartConfig.replaceFirst("'android-app'", "'wrong-app'"),
    );
    final before = file('lib/firebase_options.dart').readAsStringSync();
    final result = await runSetup(['api-key']);
    expect(result.exitCode, isNot(0));
    expect(file('lib/firebase_options.dart').readAsStringSync(), before);
    expect(
      jsonDecode(file('android/app/google-services.json').readAsStringSync()),
      _config,
    );
  });

  test('無効なキーは設定を変更する前に拒否する', () async {
    final result = await runSetup(['api-key'], key: "invalid'key");
    expect(result.exitCode, isNot(0));
    expect(file('lib/firebase_options.dart').readAsStringSync(), _dartConfig);
    expect(
      jsonDecode(file('android/app/google-services.json').readAsStringSync()),
      _config,
    );
  });

  test('インデックス取得失敗時は既存のローカルファイルを残す', () async {
    final result = await runSetup([
      'sync-indexes',
    ], failCommand: 'firebase firestore:indexes');
    expect(result.exitCode, isNot(0));
    expect(
      file('firestore.indexes.json').readAsStringSync(),
      '{"indexes":["既存"]}',
    );
  });

  test('先行処理の失敗後は次のデプロイを実行しない', () async {
    final result = await runSetup([
      'rules',
      'indexes',
    ], failCommand: 'firebase deploy --only firestore:rules');
    expect(result.exitCode, isNot(0));
    expect(commands.readAsLinesSync(), [
      'firebase projects:list',
      'firebase deploy --only firestore:rules',
    ]);
  });

  test('justから指定した処理をスクリプトへ渡せる', () async {
    success(await runSetup(['api-key'], viaJust: true));
    expectKeyUpdated();
  });
}
