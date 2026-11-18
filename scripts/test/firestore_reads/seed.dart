import 'dart:convert';
import 'dart:io';

import 'fixture.dart';

Future<Map<String, dynamic>> emulatorRequest(
  int port,
  String method,
  String path, [
  Object? body,
]) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.openUrl(
      method,
      Uri.http('127.0.0.1:$port', path),
    );
    request.headers.set('Authorization', 'Bearer owner');
    request.headers.contentType = ContentType.json;
    if (body != null) request.write(jsonEncode(body));
    final response = await request.close().timeout(const Duration(seconds: 30));
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode >= 300) {
      throw HttpException(
        'Emulator $method $path: ${response.statusCode} $text',
      );
    }
    return text.isEmpty ? {} : object(jsonDecode(text), 'Emulator response');
  } finally {
    client.close(force: true);
  }
}

Future<void> seedFixture(ReadFixture fixture) async {
  await emulatorRequest(
    9099,
    'DELETE',
    '/emulator/v1/projects/$readRegressionProjectId/accounts',
  );
  await emulatorRequest(
    8080,
    'DELETE',
    '/emulator/v1/projects/$readRegressionProjectId/databases/(default)/documents',
  );
  if (fixture.accounts.isNotEmpty) {
    final result = await emulatorRequest(
      9099,
      'POST',
      '/identitytoolkit.googleapis.com/v1/projects/$readRegressionProjectId/accounts:batchCreate',
      {
        'users': [
          for (final account in fixture.accounts)
            {
              'localId': account['id'],
              'email': account['email'],
              'rawPassword': account['password'],
              'emailVerified': account['emailVerified'],
            },
        ],
      },
    );
    if ((result['error'] as List?)?.isNotEmpty ?? false) {
      throw StateError('Authの投入に失敗しました: $result');
    }
  }
  for (var start = 0; start < fixture.documents.length; start += 200) {
    final end = (start + 200).clamp(0, fixture.documents.length);
    await emulatorRequest(
      8080,
      'POST',
      '/v1/projects/$readRegressionProjectId/databases/(default)/documents:commit',
      {
        'writes': fixture.documents
            .sublist(start, end)
            .map((doc) => doc.write)
            .toList(),
      },
    );
  }
  stdout.writeln(jsonEncode({'collectionCounts': fixture.collectionCounts}));
}

Future<void> main(List<String> args) async {
  if (args.length != 2 || !['validate', 'seed'].contains(args.first)) {
    stderr.writeln(
      '使用法: dart scripts/test/firestore_reads/seed.dart validate|seed データ.json',
    );
    exitCode = 64;
    return;
  }
  final fixture = ReadFixture.parse(
    object(jsonDecode(await File(args[1]).readAsString()), 'dataset'),
  );
  if (args.first == 'seed') {
    await seedFixture(fixture);
  } else {
    stdout.writeln(jsonEncode({'collectionCounts': fixture.collectionCounts}));
  }
}
