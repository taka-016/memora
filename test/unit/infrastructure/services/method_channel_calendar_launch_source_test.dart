import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/services/method_channel_calendar_launch_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('memora/calendar_launch');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('日時表示の要求を端末のローカル日時に変換する', () async {
    final date = DateTime.utc(2026, 11, 28, 23);
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'action': 'view', 'begin': date.millisecondsSinceEpoch},
    );
    final request = await MethodChannelCalendarLaunchSource().takePending();
    expect(request!.date, date.toLocal());
    expect(request.draft, isNull);
  });

  test('終日予定のUTC日付と翌日を指す終了日を保持する', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {
        'action': 'create',
        'begin': DateTime.utc(2026, 11, 28).millisecondsSinceEpoch,
        'end': DateTime.utc(2026, 11, 30).millisecondsSinceEpoch,
        'allDay': true,
        'title': '家族旅行',
        'description': '持ち物',
        'location': '京都',
      },
    );
    final request = await MethodChannelCalendarLaunchSource().takePending();
    expect(request!.draft!.start, DateTime.utc(2026, 11, 28));
    expect(request.draft!.end, DateTime.utc(2026, 11, 30));
    expect(request.draft!.isAllDay, isTrue);
    expect(request.draft!.title, '家族旅行');
    expect(request.draft!.memo, '持ち物');
    expect(request.draft!.locationName, '京都');
  });

  test('範囲外の日時を初期値にせず日時未指定の予定追加は受け取る', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'action': 'create', 'begin': 9223372036854775807},
    );
    final request = await MethodChannelCalendarLaunchSource().takePending();
    expect(request!.draft!.start, isNull);
    expect(request.draft!.end, isNull);
  });

  test('Android受信処理がない環境では要求なしとして扱う', () async {
    expect(await MethodChannelCalendarLaunchSource().takePending(), isNull);
  });
}
