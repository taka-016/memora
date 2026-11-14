import 'dart:async';

import 'package:memora/application/services/android_widget_launch_uri_source.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:memora/application/services/calendar/calendar_notification_gateway.dart';
import 'package:memora/application/services/calendar/calendar_notification_planner.dart';

class LocalCalendarNotificationGateway
    implements CalendarNotificationGateway, AndroidWidgetLaunchUriSource {
  LocalCalendarNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
    bool? isAndroid,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _isAndroid = isAndroid ?? Platform.isAndroid;
  final FlutterLocalNotificationsPlugin _plugin;
  final bool _isAndroid;
  final _clicks = StreamController<Uri?>.broadcast();
  @override
  Stream<Uri?> get clickedUris => _clicks.stream;
  @override
  Future<Uri?> getInitialUri() async {
    if (!_isAndroid) return null;
    await _initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? _launchUri(details?.notificationResponse?.payload)
        : null;
  }

  Future<void> dispose() => _clicks.close();
  Uri? _launchUri(String? payload) {
    if (payload == null || !payload.startsWith('calendar:')) return null;
    try {
      final data = jsonDecode(payload.substring('calendar:'.length)) as List;
      final parts = (data[0] as String).split('/');
      if (parts.length != 4) return null;
      final start = DateTime.parse(data[3] as String);
      final day = data[4] == true ? start : start.toLocal();
      final date =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return Uri(
        scheme: 'memoraWidget',
        host: 'openCalendar',
        queryParameters: {
          'groupId': parts[0],
          'eventId': parts[1],
          'date': date,
          'occurrence': DateTime.fromMicrosecondsSinceEpoch(
            int.parse(parts[2]),
            isUtc: true,
          ).toIso8601String(),
        },
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on RangeError {
      return null;
    }
  }

  Future<void>? _initialization;
  Future<void> _initialize() => _initialization ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_calendar'),
    ),
    onDidReceiveNotificationResponse: (response) {
      final uri = _launchUri(response.payload);
      if (uri != null && !_clicks.isClosed) _clicks.add(uri);
    },
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  @override
  Future<bool> isEnabled() async {
    if (!_isAndroid) return false;
    await _initialize();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isAndroid) return false;
    await _initialize();
    final allowed = await _android?.requestNotificationsPermission() ?? false;
    if (allowed) await _android?.requestExactAlarmsPermission();
    return allowed;
  }

  @override
  Future<bool> openNotificationSettings() async {
    if (!_isAndroid) return false;
    await _initialize();
    return await _plugin.openAppNotificationSettings() ?? false;
  }

  String _startText(CalendarNotificationRequest request) {
    final start = request.isAllDay
        ? request.startDateTime
        : request.startDateTime.toLocal();
    final date = '${start.year}/${start.month}/${start.day}';
    if (request.isAllDay) return '$date（終日）';
    final hour = start.hour.toString().padLeft(2, '0');
    final minute = start.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  @override
  Future<void> replace(List<CalendarNotificationRequest> requests) async {
    if (!_isAndroid) return;
    await _initialize();
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final lock = await File('${directory.path}/calendar_notifications.lock')
        .open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      final pending = await _plugin.pendingNotificationRequests();
      String payload(CalendarNotificationRequest request) =>
          'calendar:${jsonEncode([request.key, request.title, request.at.toUtc().toIso8601String(), request.startDateTime.toIso8601String(), request.isAllDay])}';
      final wanted = {
        for (final request in requests) payload(request): request,
      };
      final retained = <String, int>{};
      final used = pending.map((v) => v.id).toSet();
      for (final old in pending) {
        if (!(old.payload?.startsWith('calendar:') ?? false)) continue;
        if (wanted.containsKey(old.payload)) {
          retained[old.payload!] = old.id;
        } else {
          await _plugin.cancel(id: old.id);
          used.remove(old.id);
        }
      }
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      var id = 1;
      for (final entry in wanted.entries) {
        while (used.contains(id)) {
          id++;
        }
        final notificationId = retained[entry.key] ?? id;
        await _plugin.zonedSchedule(
          id: notificationId,
          title: entry.value.title,
          body: _startText(entry.value),
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
        used.add(notificationId);
      }
    } finally {
      await lock.unlock();
      await lock.close();
    }
  }
}
