import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';

import '../../../scripts/timetree/import_timetree.dart';
import '../../helpers/test_exception.dart';

class _LocalHttpOverrides extends HttpOverrides {}

Map<String, dynamic> configuration() => {
  'projectId': 'test-project',
  'databaseId': '(default)',
  'groupId': 'group',
  'inputIcs': 'timetree.ics',
  'reportPath': 'timetree-import.report.json',
  'accessTokenEnvironmentVariable': 'GOOGLE_OAUTH_ACCESS_TOKEN',
  'allDayExceptionTimeZone': 'Asia/Tokyo',
  'labels': {
    'existing': {'type': 'custom', 'id': 'label'},
    'new': {
      'type': 'custom',
      'new': {
        'name': '新規分類',
        'color': '#123456',
        'textColor': '#FFFFFF',
        'sortOrder': 2,
      },
    },
  },
  'mappings': [
    {'category': '分類', 'color': '#123456', 'label': 'existing'},
    {'category': null, 'color': '#212121', 'label': 'new'},
  ],
};

String calendar(List<String> entries) =>
    'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n${entries.join('\r\n')}\r\nEND:VCALENDAR\r\n';
String event(
  String uid, {
  String dates = 'DTSTART:20261102\nDTEND:20261104',
  String extra = '',
  bool classified = true,
}) =>
    '''BEGIN:VEVENT
UID:$uid
SUMMARY:予定
$dates
CREATED:20200101T010203Z
LAST-MODIFIED:20251101T020304Z
${classified ? 'CATEGORIES:分類\nCOLOR:#123456' : 'COLOR:#212121'}
$extra
END:VEVENT''';

TimeTreeImportPlan plan(String ics) {
  var next = 0;
  return buildTimeTreeImportPlan(
    ics,
    TimeTreeImportConfig.fromJson(configuration()),
    newId: () => 'id${next++}',
  );
}

void main() {
  test('折り返しとエスケープを復元し終日の終了境界・座標・元の日時と通知既定値を保持する', () {
    final result = plan(
      calendar([
        event(
          'private-source-uid',
          extra: 'DESCRIPTION:一行目\\n二行目\\,続き\r\n 折り返し\nLOCATION:東京\\;入口\nURL:https://example.com\nGEO:35.5;139.5\nBEGIN:VALARM\nDESCRIPTION:取り込まない\nTRIGGER:-PT15M\nEND:VALARM',
        ),
      ]),
    );
    expect(result.failures, isEmpty);
    final imported = result.events.single;
    expect(imported.event.memo, '一行目\n二行目,続き折り返し');
    expect(imported.event.locationName, '東京;入口');
    expect(imported.event.url, 'https://example.com');
    expect(imported.event.latitude, 35.5);
    expect(imported.event.longitude, 139.5);
    expect(imported.event.startDateTime, DateTime.utc(2026, 11, 2));
    expect(imported.event.endDateTime, DateTime.utc(2026, 11, 4));
    expect(imported.createdAt, DateTime.utc(2020, 1, 1, 1, 2, 3));
    expect(imported.updatedAt, DateTime.utc(2025, 11, 1, 2, 3, 4));
    expect(
      imported.event.notificationMinutesBefore,
      const CalendarNotificationPreferences().allDay,
    );
    expect(jsonEncode(result.report()), isNot(contains('private-source-uid')));
  });

  test('時刻付き予定のタイムゾーンとゼロ時間を維持し月末補正のルールを展開せず保持する', () {
    final result = plan(
      calendar([
        event(
          'timed',
          dates: 'DTSTART;TZID=Asia/Hong_Kong:20261102T090000\nDTEND;TZID=Asia/Hong_Kong:20261102T090000',
          extra: 'RRULE:FREQ=MONTHLY;BYMONTHDAY=2;WKST=SU',
        ),
        event(
          'utc',
          dates: 'DTSTART:20261102T010000Z\nDTEND:20261102T020000Z',
          classified: false,
        ),
      ]),
    );
    expect(result.failures, isEmpty);
    final timed = result.events.first.event;
    expect(timed.startDateTime, DateTime.utc(2026, 11, 2, 1));
    expect(timed.endDateTime, timed.startDateTime);
    expect(timed.timeZone, 'Asia/Hong_Kong');
    expect(timed.recurrenceRule, 'FREQ=MONTHLY;BYMONTHDAY=2');
    expect(
      timed.notificationMinutesBefore,
      const CalendarNotificationPreferences().timed,
    );
    expect(timed.latitude, isNull);
    expect(timed.longitude, isNull);
    expect(result.events, hasLength(2));
  });

  test('EXDATEは取消さず関連別予定を除外し手修正に必要な日時と内容だけを出力する', () {
    final result = plan(
      calendar([
        event(
          'parent-private',
          dates: 'DTSTART;VALUE=DATE:20261102\nDTEND;VALUE=DATE:20261103',
          extra: 'RRULE:FREQ=WEEKLY;WKST=SU\nEXDATE:20261108T150000Z',
        ),
        event(
          'child-private',
          extra: 'RELATED-TO:parent-private\nDESCRIPTION:変更内容',
          classified: false,
        ),
        event(
          'cancel-title',
          classified: false,
        ).replaceFirst('SUMMARY:予定', 'SUMMARY:キャンセル表記だけの通常予定'),
      ]),
    );
    expect(result.failures, isEmpty);
    expect(result.events, hasLength(2));
    expect(result.excluded, hasLength(1));
    expect(result.events.first.event.overrides, isEmpty);
    final report = jsonEncode(result.report());
    expect(report, contains('2026-11-09'));
    expect(report, contains('変更内容'));
    expect(report, contains(result.events.first.event.id));
    expect(report, isNot(contains('parent-private')));
    expect(report, isNot(contains('child-private')));
  });

  test('意味が変わるWKST・不明なルール・不正日付・元日時欠落は理由付きで失敗する', () {
    final result = plan(
      calendar([
        event('unsafe', extra: 'RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU'),
        event('unknown', extra: 'RRULE:FREQ=DAILY;BYHOUR=9'),
        event('date', dates: 'DTSTART:20260230\nDTEND:20260303'),
        event('created').replaceFirst('CREATED:20200101T010203Z', ''),
      ]),
    );
    expect(result.events, isEmpty);
    expect(result.failures, hasLength(4));
    expect(
      result.failures.every((value) => value['reason'].toString().isNotEmpty),
      isTrue,
    );
  });

  test('レポート出力に失敗しても失敗件数と理由を表示する', () async {
    final directory = await Directory.systemTemp.createTemp('memora-timetree-');
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/input.ics');
    await source.writeAsString(calendar([event('valid')]));
    final config = configuration()
      ..['inputIcs'] = source.path
      ..['reportPath'] = directory.path;
    final configFile = File('${directory.path}/config.json');
    await configFile.writeAsString(jsonEncode(config));
    final result = await Process.run('dart', [
      'run',
      'scripts/timetree/import_timetree.dart',
      configFile.path,
    ]);
    expect(result.exitCode, 1);
    expect(result.stderr.toString(), contains('成功=0、失敗=1'));
    expect(result.stderr.toString(), contains('レポート'));
  });

  group('Firestoreの一括登録', () {
    late HttpServer server;
    late FirestoreImportClient client;
    late List<Map<String, dynamic>> commits;
    var reject = false;
    var rejectionCode = 400;
    var memberExists = true;
    setUp(() async {
      commits = [];
      reject = false;
      rejectionCode = 400;
      memberExists = true;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path.endsWith(':runQuery')) {
          await utf8.decoder.bind(request).join();
          request.response.write(
            jsonEncode([
              {
                'document': {
                  'fields': {
                    'memberId': {'stringValue': 'member'},
                  },
                },
              },
            ]),
          );
        } else if (request.method == 'POST') {
          commits.add(
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>,
          );
          request.response.statusCode = reject ? rejectionCode : 200;
          request.response.write(
            jsonEncode(
              reject
                  ? {
                      'error': {'message': '拒否'},
                    }
                  : {'commitTime': '2026-11-06T00:00:00Z'},
            ),
          );
        } else {
          final name = request.uri.path.split('/').last;
          if (request.uri.path.contains('/members/') && !memberExists) {
            request.response.statusCode = 404;
          }
          request.response.write(
            jsonEncode({
              'name': name,
              'updateTime': '2026-11-01T00:00:00Z',
              'fields': {
                'groupId': {'stringValue': 'group'},
                'eventCount': {'integerValue': '7'},
              },
            }),
          );
        }
        await request.response.close();
      });
      client = HttpOverrides.runWithHttpOverrides(
        () => FirestoreImportClient(
          'test-project',
          '(default)',
          'test-token',
          endpoint: Uri.parse('http://127.0.0.1:${server.port}'),
        ),
        _LocalHttpOverrides(),
      );
    });
    tearDown(() async {
      client.close();
      await server.close(force: true);
    });

    test('予定と新規ラベルと利用件数を元日時・バージョン・参照を含む1回のCommitで保存する', () async {
      final result = plan(
        calendar([event('first'), event('second', classified: false)]),
      );
      await applyTimeTreeImportPlan(result, client);
      final writes = commits.single['writes'] as List;
      expect(writes, hasLength(4));
      final oldLabel = writes.singleWhere(
        (dynamic w) =>
            (w['update']?['name'] as String?)?.endsWith(
              '/calendar_labels/label',
            ) ??
            false,
      );
      expect(oldLabel['update']['fields']['eventCount']['integerValue'], '8');
      expect(oldLabel['currentDocument']['updateTime'], '2026-11-01T00:00:00Z');
      final eventWrites = writes
          .where(
            (dynamic w) =>
                (w['update']?['name'] as String?)?.contains(
                  '/calendar_events/',
                ) ??
                false,
          )
          .toList();
      expect(eventWrites, hasLength(2));
      final fields = eventWrites.first['update']['fields'];
      expect(fields['version']['integerValue'], '1');
      expect(fields['createdAt']['timestampValue'], '2020-01-01T01:02:03.000Z');
      expect(fields['updatedAt']['timestampValue'], '2025-11-01T02:03:04.000Z');
      expect(fields['overrideIds']['arrayValue'], isA<Map>());
      expect(
        fields['referencedLabelIds']['arrayValue']['values']
            .single['stringValue'],
        'label',
      );
      expect(eventWrites.first['currentDocument']['exists'], isFalse);
      expect(jsonEncode(commits), isNot(contains('UID')));
    });

    for (final code in [408, 500, 503, 504]) {
      test('CommitのHTTP$codeは確定失敗とせず結果確認を求める', () async {
        rejectionCode = code;
        reject = true;
        await expectLater(
          applyTimeTreeImportPlan(plan(calendar([event('valid')])), client),
          throwsA(isA<FirestoreImportOutcomeUnknown>()),
        );
        expect(commits, hasLength(1));
      });
    }

    for (final memberId in ['unrelated', 'member']) {
      test('別グループまたは削除済みメンバーのラベルでは新規登録しない（$memberId）', () async {
        memberExists = memberId != 'member';
        final config = configuration();
        (config['labels'] as Map)['existing'] = {
          'type': 'member',
          'memberId': memberId,
        };
        final result = buildTimeTreeImportPlan(
          calendar([event('member-event')]),
          TimeTreeImportConfig.fromJson(config),
        );
        await expectLater(
          applyTimeTreeImportPlan(result, client),
          throwsA(isA<FormatException>()),
        );
        expect(commits, isEmpty);
      });
    }

    test('所属中のメンバーのラベルをラベル利用件数なしで登録する', () async {
      final config = configuration();
      (config['labels'] as Map)['existing'] = {
        'type': 'member',
        'memberId': 'member',
      };
      final result = buildTimeTreeImportPlan(
        calendar([event('member-event')]),
        TimeTreeImportConfig.fromJson(config),
      );
      await applyTimeTreeImportPlan(result, client);
      final writes = commits.single['writes'] as List;
      expect(writes, hasLength(1));
      expect(
        writes.single['update']['fields']['memberId']['stringValue'],
        'member',
      );
    });

    test('登録成功後にレポートを保存できなくても成功を伝え再登録を促さない', () async {
      final messages = <String>[];
      await executeTimeTreeImport(
        plan(calendar([event('valid')])),
        client,
        saveReport: (status) async {
          if (status == '成功') throw TestException('レポート保存失敗');
        },
        output: messages.add,
      );
      expect(commits, hasLength(1));
      expect(messages.join('\n'), contains('成功=1'));
      expect(messages.join('\n'), contains('再実行しないでください'));
      expect(messages.join('\n'), isNot(contains('成功=0')));
    });
    test('変換失敗を含む場合は書き込まずCommit拒否時も一部の書き込みを再試行しない', () async {
      final invalid = plan(
        calendar([event('bad', extra: 'RRULE:FREQ=SECONDLY')]),
      );
      await expectLater(
        applyTimeTreeImportPlan(invalid, client),
        throwsA(isA<FormatException>()),
      );
      expect(commits, isEmpty);
      reject = true;
      await expectLater(
        applyTimeTreeImportPlan(plan(calendar([event('valid')])), client),
        throwsA(isA<FirestoreImportRejected>()),
      );
      expect(commits, hasLength(1));
    });
  });
}
