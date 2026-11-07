import 'dart:convert';
import 'dart:io';

import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/domain/entities/calendar/calendar_notifications.dart'
    show validateCalendarNotifications;

import 'import_timetree.dart' as timetree;

Map<String, dynamic> _map(Object? value) =>
    (value as Map).cast<String, dynamic>();
String _required(Map<String, dynamic> value, String key) {
  final text = value[key];
  if (text is! String || text.trim().isEmpty) {
    throw FormatException('$keyがありません');
  }
  return text;
}

String _id(String value) {
  if (value.isEmpty || value.contains('/') || value == '.' || value == '..') {
    throw const FormatException('取り込みレポートの予定IDが不正です');
  }
  return value;
}

List<dynamic> _values(Map<String, dynamic> fields, String key) =>
    (fields[key]?['arrayValue']?['values'] as List?) ?? const [];

class NotificationBackfillPlan {
  NotificationBackfillPlan(this.projectId, this.groupId, this.checkedEvents);
  final String projectId;
  final String groupId;
  final int checkedEvents;
  final List<Map<String, Object?>> writes = [];
  final List<Map<String, Object?>> updates = [];
  final List<Map<String, Object?>> skipped = [];

  Map<String, Object?> report(String status, {String? reason}) => {
    'status': status,
    'projectId': projectId,
    'groupId': groupId,
    'counts': {
      'checkedEvents': checkedEvents,
      'notificationsToSet': updates.length,
      'writes': writes.length,
      'skipped': skipped.length,
    },
    'updates': updates,
    'skipped': skipped,
    'reason': ?reason,
  };
}

List<String> importedEventPaths(Map<String, dynamic> report) {
  if (report['status'] != '成功') {
    throw const FormatException('成功した取り込みレポートを指定してください');
  }
  return (report['events'] as List)
      .map(
        (value) => 'calendar_events/${_id(_required(_map(value), 'eventId'))}',
      )
      .toSet()
      .toList();
}

NotificationBackfillPlan buildNotificationBackfillPlan(
  Map<String, dynamic> importReport,
  Map<String, Map<String, dynamic>?> documents,
) {
  final paths = importedEventPaths(importReport);
  final groupId = _required(importReport, 'groupId');
  final plan = NotificationBackfillPlan(
    _required(importReport, 'projectId'),
    groupId,
    paths.length,
  );
  const defaults = CalendarNotificationPreferences();

  Map<String, Object?>? notifications(
    Map<String, dynamic> document,
    String path,
  ) {
    final fields = _map(document['fields']);
    final title = fields['title']?['stringValue'] as String? ?? '';
    if (_values(fields, 'notificationMinutesBefore').isNotEmpty) {
      plan.skipped.add({'path': path, 'title': title, 'reason': '通知設定済み'});
      return null;
    }
    final allDay = fields['isAllDay']['booleanValue'] as bool;
    final minutes = allDay ? defaults.allDay : defaults.timed;
    validateCalendarNotifications(minutes, allDay);
    plan.updates.add({
      'path': path,
      'title': title,
      'isAllDay': allDay,
      'notificationMinutesBefore': minutes,
    });
    return {
      'notificationMinutesBefore': {
        'arrayValue': {
          'values': [
            for (final value in minutes) {'integerValue': '$value'},
          ],
        },
      },
    };
  }

  Map<String, Object?> write(
    Map<String, dynamic> document,
    Map<String, Object?> fields,
  ) => {
    'update': {'name': document['name'], 'fields': fields},
    'updateMask': {'fieldPaths': fields.keys.toList()},
    'currentDocument': {'updateTime': _required(document, 'updateTime')},
    'updateTransforms': [
      {'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'},
    ],
  };

  for (final path in paths) {
    final parent = documents[path];
    if (parent == null) {
      plan.skipped.add({'path': path, 'reason': '削除済み'});
      continue;
    }
    final fields = _map(parent['fields']);
    if (fields['groupId']?['stringValue'] != groupId) {
      plan.skipped.add({'path': path, 'reason': '取り込み先グループと不一致'});
      continue;
    }
    final parentFields = notifications(parent, path);
    final childWrites = <Map<String, Object?>>[];
    for (final value in _values(fields, 'overrideIds')) {
      final overrideId = _id(value['stringValue'] as String);
      final childPath = 'calendar_event_overrides/$overrideId';
      final child = documents[childPath];
      if (child == null) {
        plan.skipped.add({'path': childPath, 'reason': '個別回が存在しない'});
        continue;
      }
      final childFields = _map(child['fields']);
      if (childFields['groupId']?['stringValue'] != groupId ||
          childFields['eventId']?['stringValue'] != path.split('/').last) {
        throw const FormatException('個別回の親予定またはグループが一致しません');
      }
      if (childFields['isCancelled']?['booleanValue'] == true) {
        plan.skipped.add({'path': childPath, 'reason': '取消済みの個別回'});
        continue;
      }
      final patch = notifications(child, childPath);
      if (patch != null) childWrites.add(write(child, patch));
    }
    if (parentFields == null && childWrites.isEmpty) continue;
    final version = int.parse(fields['version']['integerValue'].toString());
    plan.writes.add(
      write(parent, {
        ...?parentFields,
        'version': {'integerValue': '${version + 1}'},
      }),
    );
    plan.writes.addAll(childWrites);
  }
  return plan;
}

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stdout.writeln(
      '使用方法: dart run scripts/timetree/set_missing_notifications.dart 設定.json [--apply]\n既定は確認のみ。取り込みレポートの予定と個別回のうち、通知が空のものだけを補完します。',
    );
    return;
  }
  timetree.FirestoreImportClient? client;
  NotificationBackfillPlan? plan;
  File? outputFile;
  try {
    if (args.length > 2 || args.skip(1).any((value) => value != '--apply')) {
      throw const FormatException('不明な引数です');
    }
    final configFile = File(args.first).absolute;
    final firebase = _map(jsonDecode(await File('.firebaserc').readAsString()));
    final config = _map(jsonDecode(await configFile.readAsString()));
    final source = File.fromUri(
      configFile.parent.uri.resolve(_required(config, 'reportPath')),
    );
    final importReport = _map(jsonDecode(await source.readAsString()));
    final projectId = _required(_map(firebase['projects']), 'default');
    if (importReport['projectId'] != projectId ||
        importReport['databaseId'] != '(default)') {
      throw const FormatException('取り込みレポートとアプリ設定の接続先が一致しません');
    }
    final paths = importedEventPaths(importReport);
    final variable = _required(config, 'accessTokenEnvironmentVariable');
    final token = Platform.environment[variable];
    if (token == null || token.trim().isEmpty) {
      throw FormatException('$variableにOAuthアクセストークンを設定してください');
    }
    client = timetree.FirestoreImportClient(projectId, '(default)', token);
    const fields = [
      'groupId',
      'title',
      'isAllDay',
      'notificationMinutesBefore',
      'version',
      'overrideIds',
      'eventId',
      'isCancelled',
    ];
    final documents = await client.readDocuments(paths, fieldPaths: fields);
    final overridePaths = <String>{};
    for (final parent in documents.values) {
      if (parent == null) continue;
      for (final value in _values(_map(parent['fields']), 'overrideIds')) {
        overridePaths.add(
          'calendar_event_overrides/${_id(value['stringValue'] as String)}',
        );
      }
    }
    documents.addAll(
      await client.readDocuments(overridePaths.toList(), fieldPaths: fields),
    );
    plan = buildNotificationBackfillPlan(importReport, documents);
    outputFile = File.fromUri(
      source.uri.resolve('timetree-notifications.report.json'),
    );
    Future<void> save(String status, {String? reason}) async {
      await outputFile!.writeAsString(
        jsonEncode(plan!.report(status, reason: reason)),
      );
    }

    await save('確認のみ');
    stdout.writeln(
      '通知補完対象=${plan.updates.length}、書き込み=${plan.writes.length}、スキップ=${plan.skipped.length}\n確認レポート: ${outputFile.path}',
    );
    if (!args.contains('--apply') || plan.writes.isEmpty) return;
    stdout.write('内容を確認し、適用する場合は「通知を設定する」と入力してください: ');
    if (stdin.readLineSync() != '通知を設定する') {
      stdout.writeln('中止しました。書き込みは行っていません');
      return;
    }
    await save('実行中');
    await client.commit(plan.writes);
    try {
      await save('成功');
    } catch (error) {
      stderr.writeln('通知の更新は成功しましたがレポートを保存できませんでした: $error');
    }
    stdout.writeln(
      '成功=${plan.updates.length}、失敗=0、スキップ=${plan.skipped.length}',
    );
  } catch (error) {
    final unknown = error is timetree.FirestoreImportOutcomeUnknown;
    final reason = unknown
        ? '更新結果を確認できませんでした。確認モードを再実行して通知の状態を確認してください'
        : error.toString();
    if (outputFile != null && plan != null) {
      try {
        await outputFile.writeAsString(
          jsonEncode(plan.report(unknown ? '結果不明' : '失敗', reason: reason)),
        );
      } catch (reportError) {
        stderr.writeln('レポートを保存できませんでした: $reportError');
      }
    }
    stderr.writeln(
      '成功=0、${unknown ? '結果不明' : '失敗'}=${plan?.updates.length ?? 0}: $reason',
    );
    exitCode = 1;
  } finally {
    client?.close();
  }
}
