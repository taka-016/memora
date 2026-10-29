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
  for (final exact in [true, false]) {
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
        key: 'event/0',
        title: '予定',
        at: DateTime.utc(2026, 10, 30, 7),
      );
      final payload =
          'calendar:${jsonEncode([request.key, request.title, request.at.toUtc().toIso8601String()])}';
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
          body: anyNamed('body'),
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
