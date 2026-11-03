import 'dart:convert';
import 'dart:io';

void main() {
  try {
    updateApiKey();
    stdout.writeln('AndroidのJSON・Dart設定を指定したFirebase用APIキーに更新しました。');
  } on FormatException {
    stderr.writeln('APIキーの形式と、JSON・Dart設定のプロジェクト・Androidアプリを確認してください。');
    exitCode = 1;
  } on FileSystemException {
    stderr.writeln('Firebase設定ファイルの配置と読み書き権限を確認してください。');
    exitCode = 1;
  }
}

void updateApiKey() {
  final key = Platform.environment['FIREBASE_API_KEY'] ?? '';
  if (!RegExp(r'^AIza[A-Za-z0-9_-]+$').hasMatch(key)) {
    throw const FormatException();
  }
  final jsonFile = File('android/app/google-services.json');
  final dartFile = File('lib/firebase_options.dart');
  final config = jsonDecode(jsonFile.readAsStringSync());
  final dartSource = dartFile.readAsStringSync();
  final android = RegExp(
    r'static const FirebaseOptions android\s*=\s*FirebaseOptions\(([\s\S]*?)\);',
  ).firstMatch(dartSource);
  if (config is! Map<String, dynamic> || android == null) {
    throw const FormatException();
  }
  final options = android.group(1)!;
  final appId = RegExp(r"\bappId:\s*'([^']+)'").firstMatch(options)?.group(1);
  final projectId = RegExp(r"\bprojectId:\s*'([^']+)'")
      .firstMatch(options)
      ?.group(1);
  final apiKey = RegExp(r"\bapiKey:\s*'[^']*'");
  final project = config['project_info'];
  final clients = config['client'];
  if (appId == null ||
      projectId == null ||
      project is! Map ||
      project['project_id'] != projectId ||
      clients is! List ||
      apiKey.allMatches(options).length != 1) {
    throw const FormatException();
  }
  final matches = clients.whereType<Map<String, dynamic>>().where((client) {
    final info = client['client_info'];
    return info is Map &&
        info['mobilesdk_app_id'] == appId &&
        info['android_client_info'] is Map;
  }).toList();
  if (matches.length != 1) throw const FormatException();

  matches.single['api_key'] = [
    {'current_key': key},
  ];
  final updatedAndroid = android
      .group(0)!
      .replaceFirst(apiKey, "apiKey: '$key'");
  final updatedDart = dartSource.replaceRange(
    android.start,
    android.end,
    updatedAndroid,
  );
  jsonFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(config)}\n',
  );
  dartFile.writeAsStringSync(updatedDart);
}
