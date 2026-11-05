import '../../../helpers/test_exception.dart';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/calendar/external_calendar_dto.dart';
import 'package:memora/application/exceptions/external_calendar_exception.dart';
import 'package:memora/infrastructure/services/method_channel_device_calendar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('memora/device_calendar');
  late MethodChannelDeviceCalendarService service;
  late List<MethodCall> calls;
  const rows = [
    {
      'id': '1',
      'name': '個人',
      'accountId': 'first',
      'accountName': 'first@example.com',
    },
    {
      'id': '2',
      'name': '家族',
      'accountId': 'first',
      'accountName': 'first@example.com',
    },
    {
      'id': '3',
      'name': '仕事',
      'accountId': 'second',
      'accountName': 'second@example.com',
    },
  ];
  setUp(() {
    calls = [];
    service = MethodChannelDeviceCalendarService(channel: channel);
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  void handle(Future<Object?> Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return handler(call);
        });
  }

  test('権限の確認だけでは許可画面を開かず明示操作で要求する', () async {
    handle((call) async => call.method == 'requestReadPermission');
    expect(await service.hasReadPermission(), isFalse);
    expect(await service.requestReadPermission(), isTrue);
    expect(calls.map((v) => v.method), [
      'hasReadPermission',
      'requestReadPermission',
    ]);
  });
  test('端末の一覧から複数アカウントを列挙し対象カレンダーだけを返す', () async {
    handle((_) async => rows);
    expect((await service.accounts()).map((v) => v.name), [
      'first@example.com',
      'second@example.com',
    ]);
    expect((await service.calendars('first')).map((v) => v.id), ['1', '2']);
    expect((await service.calendars('second')).single.name, '仕事');
  });
  test('端末の繰り返し各回と終日終了境界を予定へ変換する', () async {
    final begin = DateTime.utc(2026, 11, 2).millisecondsSinceEpoch;
    final end = DateTime.utc(2026, 11, 5).millisecondsSinceEpoch;
    handle(
      (_) async => [
        {
          'id': 'event:1',
          'calendarId': '1',
          'title': '旅行',
          'begin': begin,
          'end': end,
          'allDay': true,
          'description': '本文',
          'location': '東京',
          'recurrence': ['RRULE:FREQ=WEEKLY'],
          'timeZone': 'Asia/Tokyo',
        },
        {
          'id': 'event:2',
          'calendarId': '1',
          'title': '次の回',
          'begin': begin + 604800000,
          'end': end + 604800000,
          'allDay': false,
          'recurrence': ['RRULE:FREQ=WEEKLY'],
          'timeZone': 'Asia/Tokyo',
        },
      ],
    );
    final from = DateTime(2026, 10);
    final to = DateTime(2027, 1);
    final events = await service.events(
      'first',
      [const ExternalCalendarDto(id: '1', name: '個人')],
      from,
      to,
    );
    expect(calls.single.method, 'events');
    expect(calls.single.arguments, {
      'calendarIds': ['1'],
      'from': from.millisecondsSinceEpoch,
      'to': to.millisecondsSinceEpoch,
    });
    expect(events.first.accountId, 'first');
    expect(events.first.startDateTime, DateTime.utc(2026, 11, 2));
    expect(events.first.endDateTime, DateTime.utc(2026, 11, 4));
    expect(events.first.memo, '本文');
    expect(events.first.locationName, '東京');
    expect(events.first.isRecurring, isTrue);
    expect(events.first.recurrence, ['RRULE:FREQ=WEEKLY']);
    expect(events.last.endDateTime.millisecondsSinceEpoch, end + 604800000);
    expect(events.first.id, isNot(events.last.id));
  });
  test('選択が空なら端末の予定へアクセスしない', () async {
    handle((_) async => throw TestException('呼び出さない'));
    expect(
      await service.events('first', [], DateTime(2026, 10), DateTime(2027, 1)),
      isEmpty,
    );
    expect(calls, isEmpty);
  });
  test('端末権限の拒否を読み取り許可のエラーとして返す', () async {
    handle(
      (_) async => throw PlatformException(code: 'calendar_permission_denied'),
    );
    await expectLater(
      service.accounts(),
      throwsA(
        isA<ExternalCalendarException>().having(
          (v) => v.kind,
          '種別',
          ExternalCalendarFailure.permission,
        ),
      ),
    );
  });
}
