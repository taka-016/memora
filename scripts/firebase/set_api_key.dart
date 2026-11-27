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
  final declarations = RegExp(
    r'static const FirebaseOptions (android|androidRelease|androidDebug)\s*=\s*([\s\S]*?);',
  ).allMatches(dartSource).toList();
  final android = declarations
      .where(
        (match) =>
            match.group(1) == 'androidRelease' ||
            (match.group(1) == 'android' &&
                match.group(2)!.startsWith('FirebaseOptions(')),
      )
      .firstOrNull;
  if (config is! Map<String, dynamic> || android == null) {
    throw const FormatException();
  }
  final options = android.group(2)!;
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

  final release = matches.single;
  final packageName =
      release['client_info']['android_client_info']['package_name'];
  final debugClients = clients.whereType<Map<String, dynamic>>().where((
    client,
  ) {
    final info = client['client_info'];
    return info is Map &&
        info['android_client_info'] is Map &&
        info['android_client_info']['package_name'] == '$packageName.debug';
  }).toList();
  if (debugClients.length > 1 ||
      (declarations.any((match) => match.group(1) == 'androidDebug') &&
          debugClients.isEmpty)) {
    throw const FormatException();
  }
  final debugAppId =
      debugClients.firstOrNull?['client_info']['mobilesdk_app_id'];
  if (debugClients.isNotEmpty &&
      (debugAppId is! String ||
          !RegExp(r'^[A-Za-z0-9:_-]+$').hasMatch(debugAppId) ||
          debugAppId == appId)) {
    throw const FormatException();
  }
  for (final client in [release, ...debugClients]) {
    client['api_key'] = [
      {'current_key': key},
    ];
  }
  final updatedOptions = options.replaceFirst(apiKey, "apiKey: '$key'");
  var updatedDart = dartSource;
  if (debugClients.isEmpty) {
    updatedDart = dartSource.replaceRange(
      android.start,
      android.end,
      'static const FirebaseOptions android = $updatedOptions;',
    );
  } else {
    final debugOptions = updatedOptions.replaceFirst(
      RegExp(r"\bappId:\s*'[^']*'"),
      "appId: '$debugAppId'",
    );
    final replacement =
        '''static const FirebaseOptions android =
      bool.fromEnvironment('dart.vm.product') || bool.fromEnvironment('dart.vm.profile')
          ? androidRelease : androidDebug;

  static const FirebaseOptions androidRelease = $updatedOptions;

  static const FirebaseOptions androidDebug = $debugOptions;''';
    for (var index = 1; index < declarations.length; index++) {
      if (dartSource
          .substring(declarations[index - 1].end, declarations[index].start)
          .trim()
          .isNotEmpty) {
        throw const FormatException();
      }
    }
    updatedDart = dartSource.replaceRange(
      declarations.first.start,
      declarations.last.end,
      replacement,
    );
  }
  jsonFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(config)}\n',
  );
  dartFile.writeAsStringSync(updatedDart);
}
