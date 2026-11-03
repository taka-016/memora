import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/application/services/calendar/external_calendar_auth_service.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/infrastructure/queries/calendar/google_calendar_query_service.dart';

@GenerateNiceMocks([MockSpec<ExternalCalendarAuthService>()])
import 'google_calendar_query_service_test.mocks.dart';

void main() {
  late MockExternalCalendarAuthService auth;
  setUp(() {
    auth = MockExternalCalendarAuthService();
    when(auth.accessToken('account')).thenAnswer((_) async => 'token');
    when(auth.accessToken('account', invalidToken: 'token'))
        .thenAnswer((_) async => 'renewed');
  });
  test('カレンダー一覧の全ページを読み取り認証を付けて取得する', () async {
    var count = 0;
    final query = GoogleCalendarQueryService(auth, MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.headers['Authorization'], 'Bearer token');
      expect(request.url.path, '/calendar/v3/users/me/calendarList');
      count++;
      expect(request.url.queryParameters['pageToken'], count == 1 ? null : 'next');
      return http.Response(jsonEncode({
        'items': [{'id': '$count', 'summary': '予定$count'}],
        if (count == 1) 'nextPageToken': 'next',
      }), 200);
    }));
    final calendars = await query.calendars('account');
    expect(calendars.map((v) => v.name), ['予定1', '予定2']);
  });
  test('期間・選択IDを渡し繰り返しの展開済み各回と終日境界を変換する', () async {
    var count = 0;
    final query = GoogleCalendarQueryService(auth, MockClient((request) async {
      count++;
      expect(request.url.pathSegments, ['calendar', 'v3', 'calendars', 'a/b@example.com', 'events']);
      expect(request.url.queryParameters['singleEvents'], 'true');
      expect(request.url.queryParameters['timeMin'], DateTime(2026, 11).toUtc().toIso8601String());
      expect(request.url.queryParameters['timeMax'], DateTime(2026, 12).toUtc().toIso8601String());
      if (count == 1) return http.Response(jsonEncode({
        'items': [
          {'id': 'all', 'summary': '旅行', 'description': '本文', 'start': {'date': '2026-11-01'}, 'end': {'date': '2026-11-04'}},
          {'id': 'cancel', 'status': 'cancelled'},
        ], 'nextPageToken': 'second',
      }), 200);
      expect(request.url.queryParameters['pageToken'], 'second');
      return http.Response(jsonEncode({'items': [
        {'id': 'instance', 'summary': '変更後', 'recurringEventId': 'series', 'start': {'dateTime': '2026-11-05T09:00:00+09:00'}, 'end': {'dateTime': '2026-11-05T10:00:00+09:00'}},
      ]}), 200);
    }));
    final events = await query.events('account', [const ExternalCalendarDto(id: 'a/b@example.com', name: '仕事')], DateTime(2026, 11), DateTime(2026, 12));
    expect(events.length, 2);
    expect(events.first.endDateTime, DateTime.utc(2026, 11, 3));
    expect(events.first.calendarName, '仕事');
    expect(events.first.memo, '本文');
    expect(events.last.startDateTime, DateTime.utc(2026, 11, 5));
    expect(events.last.isRecurring, isTrue);
  });
  for (final status in [401, 403, 404, 429, 500]) {
    test('HTTP$statusを分類し401だけ1回トークンを再取得する', () async {
      var count = 0;
      final query = GoogleCalendarQueryService(auth, MockClient((request) async {
        count++;
        if (count == 2) expect(request.headers['Authorization'], 'Bearer renewed');
        return http.Response('{}', status);
      }));
      await expectLater(query.calendars('account'), throwsA(isA<ExternalCalendarException>().having((v) => v.kind, '種別', switch (status) {
        401 => ExternalCalendarFailure.authentication,
        403 => ExternalCalendarFailure.permission,
        404 => ExternalCalendarFailure.unavailable,
        _ => ExternalCalendarFailure.network,
      })));
      expect(count, status == 401 ? 2 : 1);
    });
  }
  test('401の再取得後は同じページを再試行して成功する', () async {
    var count = 0;
    final query = GoogleCalendarQueryService(auth, MockClient((request) async {
      count++;
      return http.Response(count == 1 ? '{}' : '{"items": [{"id": "c", "summary": "予定"}]}', count == 1 ? 401 : 200);
    }));
    expect((await query.calendars('account')).single.id, 'c');
    verify(auth.accessToken('account', invalidToken: 'token')).called(1);
  });
}
