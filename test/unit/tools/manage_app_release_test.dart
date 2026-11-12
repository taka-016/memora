import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/firebase/manage_app_release.dart';

class _LocalHttpOverrides extends HttpOverrides {}

void main() {
  late HttpServer server;
  late FirestoreReleaseClient client;
  late Map<String, Map<String, dynamic>> documents;
  late List<Map<String, dynamic>> commits;
  late int revision;
  late int rejectedCommits;
  late int rejectionStatus;
  late String rejectionCode;
  const counter = 'app_release/build_counter';
  const availability = 'app_settings/availability';
  const root = 'projects/test-project/databases/(default)/documents';

  Map<String, dynamic> document(Map<String, dynamic> fields) => {
    'fields': fields,
    'updateTime': '2026-11-13T00:00:00.${++revision}Z',
  };

  setUp(() async {
    documents = {};
    commits = [];
    revision = 0;
    rejectedCommits = 0;
    rejectionStatus = 400;
    rejectionCode = 'FAILED_PRECONDITION';
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test-token',
      );
      request.response.headers.contentType = ContentType.json;
      if (request.method == 'GET') {
        final path = request.uri.path.substring('/v1/$root/'.length);
        final value = documents[path];
        request.response.statusCode = value == null ? 404 : 200;
        request.response.write(
          jsonEncode(
            value ??
                {
                  'error': {'status': 'NOT_FOUND'},
                },
          ),
        );
      } else {
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        commits.add(body);
        final write = (body['writes'] as List).single as Map;
        final update = write['update'] as Map;
        final path = (update['name'] as String).substring('$root/'.length);
        final old = documents[path];
        final condition = write['currentDocument'] as Map;
        final valid = old == null
            ? condition['exists'] == false
            : condition['updateTime'] == old['updateTime'];
        if (rejectedCommits > 0 || !valid) {
          if (rejectedCommits > 0) rejectedCommits--;
          request.response.statusCode = rejectionStatus;
          request.response.write(
            jsonEncode({
              'error': {'status': rejectionCode},
            }),
          );
        } else {
          final fields = {
            ...?old?['fields'] as Map?,
            ...update['fields'] as Map,
          };
          documents[path] = document(fields.cast<String, dynamic>());
          request.response.write('{}');
        }
      }
      await request.response.close();
    });
    client = HttpOverrides.runWithHttpOverrides(
      () => FirestoreReleaseClient(
        'test-project',
        'test-token',
        initialBuildNumber: 1,
        endpoint: Uri.parse('http://127.0.0.1:${server.port}'),
      ),
      _LocalHttpOverrides(),
    );
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
  });

  test('初回はpubspecの番号を現在値として読み取りだけ行いリリースで次の番号を発行する', () async {
    expect(await client.currentBuildNumber(), 1);
    expect(commits, isEmpty);
    expect(await client.allocateBuildNumber(), 2);
    expect(await client.allocateBuildNumber(), 3);
    expect(await client.currentBuildNumber(), 3);
    expect(documents[availability], isNull);
    expect(documents[counter]!['fields']['buildNumber'], {'integerValue': '3'});
  });

  test('同時リリースでも番号を重複させず現在値を進める', () async {
    final numbers = await Future.wait(
      List.generate(3, (_) => client.allocateBuildNumber()),
    );
    expect(numbers.toSet(), {2, 3, 4});
    expect(await client.currentBuildNumber(), 4);
  });

  test('競合だけを再取得して再試行し権限拒否では繰り返さない', () async {
    rejectedCommits = 1;
    expect(await client.allocateBuildNumber(), 2);
    expect(commits, hasLength(2));
    rejectedCommits = 1;
    rejectionStatus = 403;
    rejectionCode = 'PERMISSION_DENIED';
    await expectLater(
      client.allocateBuildNumber(),
      throwsA(isA<FirestoreReleaseException>()),
    );
    expect(commits, hasLength(3));
  });

  test('競合が続く場合は有限回で終了する', () async {
    rejectedCommits = 10;
    await expectLater(
      client.allocateBuildNumber(),
      throwsA(isA<FirestoreReleaseException>()),
    );
    expect(commits, hasLength(5));
  });

  test('メンテナンス中に最低対応番号を変えても停止フラグを維持する', () async {
    documents[counter] = document({
      'buildNumber': {'integerValue': '16'},
    });
    documents[availability] = document({
      'minimumBuildNumber': {'integerValue': '1'},
      'isMaintenance': {'booleanValue': true},
    });
    await client.requireUpdate(16);
    expect(documents[availability]!['fields'], {
      'minimumBuildNumber': {'integerValue': '16'},
      'isMaintenance': {'booleanValue': true},
    });
    expect(commits.single['writes'][0]['updateMask']['fieldPaths'], [
      'minimumBuildNumber',
    ]);
  });

  test('未作成の設定を初期化してメンテナンスを切り替え最低対応番号を維持する', () async {
    await client.setMaintenance(true);
    expect(documents[availability]!['fields'], {
      'minimumBuildNumber': {'integerValue': '0'},
      'isMaintenance': {'booleanValue': true},
    });
    await client.requireUpdate(1);
    await client.setMaintenance(false);
    expect(documents[availability]!['fields'], {
      'minimumBuildNumber': {'integerValue': '1'},
      'isMaintenance': {'booleanValue': false},
    });
    expect(documents[counter], isNull);
  });

  test('未採番の番号と範囲外の番号で更新必須化せず0で制限を解除できる', () async {
    for (final number in [-1, 2, 2100000001]) {
      await expectLater(
        client.requireUpdate(number),
        throwsA(isA<FormatException>()),
      );
    }
    expect(commits, isEmpty);
    await client.requireUpdate(0);
    expect(documents[availability]!['fields']['minimumBuildNumber'], {
      'integerValue': '0',
    });
  });

  test('Androidの上限に達したら採番しない', () async {
    documents[counter] = document({
      'buildNumber': {'integerValue': '2100000000'},
    });
    await expectLater(
      client.allocateBuildNumber(),
      throwsA(isA<FormatException>()),
    );
    expect(commits, isEmpty);
  });
}
