import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';

class LocalCalendarNotificationGateway implements CalendarNotificationGateway {
  LocalCalendarNotificationGateway();
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;
  Future<void> _initialize() => _initialization ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_calendar'),
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  @override
  Future<bool> isEnabled() async {
    if (!Platform.isAndroid) return false;
    await _initialize();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    await _initialize();
    final allowed = await _android?.requestNotificationsPermission() ?? false;
    if (allowed) await _android?.requestExactAlarmsPermission();
    return allowed;
  }

  @override
  Future<void> replace(List<CalendarNotificationRequest> requests) async {
    if (!Platform.isAndroid) return;
    await _initialize();
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final lock = await File('${directory.path}/calendar_notifications.lock')
        .open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      final pending = await _plugin.pendingNotificationRequests();
      String payload(CalendarNotificationRequest request) =>
          'calendar:${jsonEncode([request.key, request.title, request.at.toUtc().toIso8601String()])}';
      final wanted = {
        for (final request in requests) payload(request): request,
      };
      final retained = <String>{};
      final used = pending.map((v) => v.id).toSet();
      for (final old in pending) {
        if (!(old.payload?.startsWith('calendar:') ?? false)) continue;
        if (wanted.containsKey(old.payload)) {
          retained.add(old.payload!);
        } else {
          await _plugin.cancel(id: old.id);
          used.remove(old.id);
        }
      }
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      var id = 1;
      for (final entry in wanted.entries) {
        if (retained.contains(entry.key)) continue;
        while (used.contains(id)) {
          id++;
        }
        await _plugin.zonedSchedule(
          id: id,
          title: entry.value.title,
          body: '予定の時間をお知らせします',
          scheduledDate: tz.TZDateTime.from(entry.value.at, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'calendar_events',
              '予定の通知',
              channelDescription: 'グループの予定をお知らせします',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: entry.key,
        );
        used.add(id);
      }
    } finally {
      await lock.unlock();
      await lock.close();
    }
  }
}
