import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';
import 'package:memora/infrastructure/services/local_calendar_notification_gateway.dart';

import 'local_calendar_notification_gateway_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<FlutterLocalNotificationsPlugin>(),
  MockSpec<AndroidFlutterLocalNotificationsPlugin>(),
])
void main() {
  late PathProviderPlatform previous;
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('calendar-notification-');
    previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _PathProvider(directory.path);
  });
  tearDown(() async {
    PathProviderPlatform.instance = previous;
    await directory.delete(recursive: true);
  });
  test('通知タップとコールド起動から元グループ・予定・個別回・表示日を渡す', () async {
    final plugin = MockFlutterLocalNotificationsPlugin();
    final occurrence = DateTime.utc(2026, 11, 2);
    final payload = 'calendar:${jsonEncode(['g/e/${occurrence.microsecondsSinceEpoch}/0', '予定', '2026-11-01T09:00:00.000Z', occurrence.toIso8601String(), true])}';
    final response = NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: payload);
    when(plugin.getNotificationAppLaunchDetails()).thenAnswer((_) async => NotificationAppLaunchDetails(true, notificationResponse: response));
    final gateway = LocalCalendarNotificationGateway(plugin: plugin, isAndroid: true);
    final uri = await gateway.getInitialUri();
    expect(uri!.host.toLowerCase(), 'opencalendar');
    expect(uri.queryParameters, containsPair('groupId', 'g'));
    expect(uri.queryParameters, containsPair('eventId', 'e'));
    expect(uri.queryParameters, containsPair('date', '2026-11-02'));
    expect(DateTime.parse(uri.queryParameters['occurrence']!), occurrence);
    final callback = verify(plugin.initialize(settings: anyNamed('settings'), onDidReceiveNotificationResponse: captureAnyNamed('onDidReceiveNotificationResponse'))).captured.single as void Function(NotificationResponse);
    final clicked = gateway.clickedUris.first;
    callback(response);
    expect(await clicked, uri);
  });

  for (final (exact, isAllDay, expectedBody) in [
    (true, false, '2026/10/30 14:00'),
    (false, true, '2026/10/30（終日）'),
  ]) {
    test('OSが予約を失っても記録済みIDで再予約し、正確なアラーム権限$exactに従う', () async {
      final plugin = MockFlutterLocalNotificationsPlugin();
      final android = MockAndroidFlutterLocalNotificationsPlugin();
      when(
        plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(android.canScheduleExactNotifications())
          .thenAnswer((_) async => exact);
      final request = CalendarNotificationRequest(
        key: 'group/event/1793368800000000/0',
        title: '予定',
        at: DateTime.utc(2026, 10, 29, 7),
        startDateTime: DateTime(2026, 10, 30, 14),
        isAllDay: isAllDay,
      );
      final payload =
          'calendar:${jsonEncode([request.key, request.title, request.at.toUtc().toIso8601String(), request.startDateTime.toIso8601String(), request.isAllDay])}';
      when(plugin.pendingNotificationRequests()).thenAnswer(
        (_) async => [
          PendingNotificationRequest(7, request.title, '', payload),
          const PendingNotificationRequest(8, '削除済み', '', 'calendar:old'),
          const PendingNotificationRequest(9, '別機能', '', 'other'),
        ],
      );
      final gateway = LocalCalendarNotificationGateway(
        plugin: plugin,
        isAndroid: true,
      );
      await gateway.replace([request]);
      verify(plugin.cancel(id: 8)).called(1);
      verifyNever(plugin.cancel(id: 9));
      verify(
        plugin.zonedSchedule(
          id: 7,
          scheduledDate: anyNamed('scheduledDate'),
          notificationDetails: anyNamed('notificationDetails'),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: request.title,
          body: expectedBody,
          payload: payload,
        ),
      ).called(1);
    });
  }
}

class _PathProvider extends PathProviderPlatform {
  _PathProvider(this.path);
  final String path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
}
