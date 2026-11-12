import 'dart:convert';
import 'dart:io';

const _maximumBuildNumber = 2100000000;

class FirestoreReleaseException implements Exception {
  const FirestoreReleaseException(this.statusCode, this.code);
  final int statusCode;
  final String code;

  bool get isConflict =>
      code == 'FAILED_PRECONDITION' ||
      code == 'ABORTED' ||
      code == 'ALREADY_EXISTS';

  @override
  String toString() => 'Firestoreの操作に失敗しました（HTTP $statusCode、$code）';
}

class FirestoreReleaseClient {
  FirestoreReleaseClient(
    this.projectId,
    this._token, {
    required this.initialBuildNumber,
    Uri? endpoint,
  }) : _endpoint = endpoint ?? Uri.parse('https://firestore.googleapis.com');

  final String projectId;
  final String _token;
  final int initialBuildNumber;
  final Uri _endpoint;
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20);
  String get _documentRoot =>
      'projects/$projectId/databases/(default)/documents';

  Future<Map<String, dynamic>?> _request(
    String method,
    String suffix, [
    Map<String, Object?>? body,
  ]) async {
    Future<Map<String, dynamic>?> send() async {
      final request = await _http.openUrl(
        method,
        _endpoint.replace(path: '/v1/$_documentRoot$suffix'),
      );
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_token');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final text = await utf8.decoder.bind(response).join();
      if (response.statusCode == 404 && method == 'GET') return null;
      final data = (jsonDecode(text) as Map).cast<String, dynamic>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FirestoreReleaseException(
          response.statusCode,
          (data['error'] as Map?)?['status'] as String? ?? 'UNKNOWN',
        );
      }
      return data;
    }

    return await send().timeout(const Duration(seconds: 20));
  }

  int _buildNumber(Map<String, dynamic>? document) {
    final value = document == null
        ? initialBuildNumber
        : int.parse('${document['fields']['buildNumber']['integerValue']}');
    if (value < 1 || value > _maximumBuildNumber) {
      throw const FormatException('ビルド番号は1〜2100000000の整数で指定してください');
    }
    return value;
  }

  Future<int> currentBuildNumber() async =>
      _buildNumber(await _request('GET', '/app_release/build_counter'));

  Future<T> _retryConflict<T>(Future<T> Function() action) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await action();
      } on FirestoreReleaseException catch (error) {
        if (!error.isConflict || attempt >= 4) rethrow;
      }
    }
  }

  Future<void> _write(
    String path,
    Map<String, Object?> fields,
    Map<String, dynamic>? previous,
  ) async {
    await _request('POST', ':commit', {
      'writes': [
        {
          'update': {'name': '$_documentRoot/$path', 'fields': fields},
          'updateMask': {'fieldPaths': fields.keys.toList()},
          'currentDocument': previous == null
              ? {'exists': false}
              : {'updateTime': previous['updateTime']},
        },
      ],
    });
  }

  Future<int> allocateBuildNumber() async => _retryConflict(() async {
    const path = 'app_release/build_counter';
    final previous = await _request('GET', '/$path');
    final next = _buildNumber(previous) + 1;
    if (next > _maximumBuildNumber) {
      throw const FormatException('ビルド番号がAndroidの上限に達しています');
    }
    await _write(path, {
      'buildNumber': {'integerValue': '$next'},
    }, previous);
    return next;
  });

  Future<void> _updateAvailability(String field, Object value) async =>
      _retryConflict(() async {
        const path = 'app_settings/availability';
        final previous = await _request('GET', '/$path');
        await _write(path, {
          if (previous == null) ...{
            'minimumBuildNumber': {'integerValue': '0'},
            'isMaintenance': {'booleanValue': false},
          },
          field: value,
        }, previous);
      });

  Future<void> requireUpdate(int minimumBuildNumber) async {
    if (minimumBuildNumber < 0 || minimumBuildNumber > _maximumBuildNumber) {
      throw const FormatException('最低対応ビルド番号は0〜2100000000の整数で指定してください');
    }
    if (minimumBuildNumber > await currentBuildNumber()) {
      throw const FormatException('採番済みのビルド番号を指定してください');
    }
    await _updateAvailability('minimumBuildNumber', {
      'integerValue': '$minimumBuildNumber',
    });
  }

  Future<void> setMaintenance(bool enabled) async =>
      _updateAvailability('isMaintenance', {'booleanValue': enabled});

  void close() => _http.close(force: true);
}

Future<void> main(List<String> arguments) async {
  FirestoreReleaseClient? client;
  try {
    final command = arguments.isEmpty ? '' : arguments.first;
    final valid = switch (command) {
      'current' || 'next' => arguments.length == 1,
      'require-update' =>
        arguments.length == 2 && RegExp(r'^\d+$').hasMatch(arguments[1]),
      'maintenance' =>
        arguments.length == 2 && ['on', 'off'].contains(arguments[1]),
      _ => false,
    };
    if (!valid) {
      throw const FormatException(
        'current / next / require-update <番号> / maintenance on|off を指定してください',
      );
    }
    final configuration =
        jsonDecode(await File('.firebaserc').readAsString()) as Map;
    final projectId = (configuration['projects'] as Map?)?['default'];
    if (projectId is! String ||
        !RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(projectId)) {
      throw const FormatException('.firebasercの既定のFirebaseプロジェクトを設定してください');
    }
    final pubspec = await File('pubspec.yaml').readAsString();
    final match = RegExp(
      r'^version:\s*\S+\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);
    if (match == null)
      throw const FormatException('pubspec.yamlにビルド番号を設定してください');
    var token = Platform.environment['FIRESTORE_ACCESS_TOKEN']?.trim();
    if (token == null || token.isEmpty) {
      final result = await Process.run('gcloud', [
        'auth',
        'print-access-token',
      ]);
      if (result.exitCode != 0 || result.stdout.toString().trim().isEmpty) {
        throw const FormatException('gcloud auth loginで管理用アカウントにログインしてください');
      }
      token = result.stdout.toString().trim();
    }
    client = FirestoreReleaseClient(
      projectId,
      token,
      initialBuildNumber: int.parse(match.group(1)!),
    );
    switch (command) {
      case 'current':
        stdout.writeln(await client.currentBuildNumber());
      case 'next':
        stdout.writeln(await client.allocateBuildNumber());
      case 'require-update':
        final number = int.parse(arguments[1]);
        await client.requireUpdate(number);
        stdout.writeln('最低対応ビルド番号を$numberに設定しました（$projectId）');
      case 'maintenance':
        await client.setMaintenance(arguments[1] == 'on');
        stdout.writeln(
          'メンテナンスを${arguments[1] == 'on' ? '開始' : '終了'}しました（$projectId）',
        );
    }
  } on ProcessException {
    stderr.writeln(
      'Google Cloud CLIをインストールしてgcloud auth loginを実行するか、FIRESTORE_ACCESS_TOKENを設定してください',
    );
    exitCode = 1;
  } on FileSystemException {
    stderr.writeln('リポジトリ直下で実行し、.firebasercとpubspec.yamlを確認してください');
    exitCode = 1;
  } catch (error) {
    stderr.writeln('リリース設定の操作に失敗しました: $error');
    exitCode = 1;
  } finally {
    client?.close();
  }
}
