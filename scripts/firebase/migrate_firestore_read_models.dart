import 'dart:convert';
import 'dart:io';

import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/application/services/calendar/calendar_recurrence_expander.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:uuid/uuid.dart';

import '../timetree/import_timetree.dart' show FirestoreImportClient;

Map<String, Object?> fields(Map<String, dynamic> document) =>
    (document['fields'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, decode(value as Map<String, dynamic>)),
    );
Object? decode(Map<String, dynamic> value) {
  if (value.containsKey('timestampValue')) {
    return DateTime.parse(value['timestampValue'] as String);
  }
  if (value.containsKey('integerValue')) {
    return int.parse('${value['integerValue']}');
  }
  if (value.containsKey('arrayValue')) {
    return ((value['arrayValue'] as Map)['values'] as List? ?? [])
        .map((v) => decode((v as Map).cast<String, dynamic>()))
        .toList();
  }
  return value['stringValue'] ?? value['booleanValue'] ?? value['doubleValue'];
}

Map<String, Object?> encode(Object? value) => switch (value) {
  null => {'nullValue': null},
  bool() => {'booleanValue': value},
  int() => {'integerValue': '$value'},
  double() => {'doubleValue': value},
  String() => {'stringValue': value},
  DateTime() => {'timestampValue': value.toUtc().toIso8601String()},
  List() => {
    'arrayValue': {'values': value.map(encode).toList()},
  },
  _ => throw const FormatException('保存できない値です'),
};
CalendarEventDto event(Map<String, Object?> data, String id) =>
    CalendarEventDto(
      id: id,
      version: data['version'] as int?,
      groupId: data['groupId'] as String,
      labelType: data['labelType'] as String,
      labelId: data['labelId'] as String? ?? '',
      memberId: data['memberId'] as String? ?? '',
      title: data['title'] as String,
      startDateTime: data['startDateTime'] as DateTime,
      endDateTime: data['endDateTime'] as DateTime,
      isAllDay: data['isAllDay'] as bool,
      recurrenceRule: data['recurrenceRule'] as String?,
      timeZone: data['timeZone'] as String?,
    );

class CalendarMigrationPlan {
  CalendarMigrationPlan(
    this.parent,
    this.cancellations,
    this.independent,
    this.labelDeltas,
  );
  final Map<String, Object?> parent;
  final Map<String, Map<String, Object?>> cancellations;
  final Map<String, Map<String, Object?>> independent;
  final Map<String, int> labelDeltas;
}

CalendarMigrationPlan? buildCalendarMigrationPlan(
  String parentId,
  Map<String, Object?> parent,
  Map<String, Map<String, Object?>> overrides, {
  String Function()? newId,
}) {
  if (parent['calendarFormatVersion'] == 2) return null;
  final source = event(parent, parentId);
  final cancellations = <String, Map<String, Object?>>{};
  final independent = <String, Map<String, Object?>>{};
  final afterReferences = <String, int>{
    if (source.labelType == 'custom') source.labelId: 1,
  };
  for (final entry in overrides.entries) {
    final data = entry.value;
    final original = data['originalStartDateTime'] as DateTime;
    final key = source.isAllDay
        ? DateTime.utc(original.year, original.month, original.day)
        : original.toUtc();
    cancellations[entry.key] = {
      'eventId': parentId,
      'groupId': source.groupId,
      'originalStartDateTime': key,
      'originalEndDateTime': key.add(source.duration),
      'isCancelled': true,
      if (data['createdAt'] != null) 'createdAt': data['createdAt'],
      if (data['updatedAt'] != null) 'updatedAt': data['updatedAt'],
    };
    if (data['isCancelled'] == true) continue;
    final id = newId?.call() ?? const Uuid().v4();
    final labelType = data['labelType'] as String;
    final labelId = data['labelId'] as String?;
    if (labelType == 'custom') {
      afterReferences.update(labelId!, (value) => value + 1, ifAbsent: () => 1);
    }
    independent[id] = {
      for (final name in [
        'title',
        'url',
        'memo',
        'locationName',
        'latitude',
        'longitude',
        'startDateTime',
        'endDateTime',
        'isAllDay',
        'notificationMinutesBefore',
        'createdAt',
        'updatedAt',
      ])
        if (data.containsKey(name)) name: data[name],
      'groupId': source.groupId,
      'labelType': labelType,
      'labelId': labelType == 'custom' ? labelId : null,
      'memberId': labelType == 'member' ? data['memberId'] : null,
      'recurrenceRule': null,
      'timeZone': null,
      'overrideIds': <String>[],
      'referencedLabelIds': [if (labelType == 'custom') labelId],
      'version': 1,
      'recurrenceEndDateTime': data['endDateTime'],
      'calendarFormatVersion': 2,
    };
  }
  final before = (parent['referencedLabelIds'] as List).cast<String>().toSet();
  final deltas = <String, int>{
    for (final id in {...before, ...afterReferences.keys})
      id: (afterReferences[id] ?? 0) - (before.contains(id) ? 1 : 0),
  }..removeWhere((_, delta) => delta == 0);
  return CalendarMigrationPlan(
    {
      ...parent,
      'version': (parent['version'] as int) + 1,
      'calendarFormatVersion': 2,
      'recurrenceEndDateTime':
          CalendarRecurrenceExpander(IanaCalendarTimeZone())
              .seriesEndDateTime(source) ??
          DateTime.utc(9999, 12, 31, 23, 59, 59),
      'overrideIds': overrides.keys.toList(),
      'referencedLabelIds': [if (source.labelType == 'custom') source.labelId],
    },
    cancellations,
    independent,
    deltas,
  );
}

Map<String, Object?> write(
  String name,
  Map<String, Object?> data,
  Map<String, Object?> condition,
) => {
  'update': {
    'name': name,
    'fields': data.map((key, value) => MapEntry(key, encode(value))),
  },
  'currentDocument': condition,
};

List<Map<String, Object?>> calendarMigrationWrites(
  CalendarMigrationPlan plan,
  Map<String, dynamic> document,
  Map<String, Map<String, dynamic>> children,
  Map<String, Map<String, dynamic>> labels,
  String root,
) {
  final writes = <Map<String, Object?>>[];
  for (final entry in plan.labelDeltas.entries) {
    final label = labels[entry.key]!;
    final data = fields(label);
    writes.add(
      write(
        label['name'] as String,
        {...data, 'eventCount': (data['eventCount'] as int) + entry.value},
        {'updateTime': label['updateTime']},
      ),
    );
  }
  writes.add(
    write(document['name'] as String, plan.parent, {
      'updateTime': document['updateTime'],
    }),
  );
  for (final entry in plan.cancellations.entries) {
    writes.add(
      write(children[entry.key]!['name'] as String, entry.value, {
        'updateTime': children[entry.key]!['updateTime'],
      }),
    );
  }
  for (final entry in plan.independent.entries) {
    writes.add(
      write('$root/calendar_events/${entry.key}', entry.value, {
        'exists': false,
      }),
    );
  }
  return writes;
}

List<Map<String, Object?>> tripChildrenGroupMigrationWrites(
  Map<String, dynamic> parent,
  List<Map<String, dynamic>> children,
) {
  final parentFields = parent['fields'] as Map;
  final groupId = parentFields['groupId']['stringValue'] as String;
  final writes = <Map<String, Object?>>[];
  for (final child in children) {
    if ((child['fields'] as Map)['groupId']?['stringValue'] == groupId) {
      continue;
    }
    writes.add({
      'update': {
        'name': child['name'],
        'fields': {
          'groupId': {'stringValue': groupId},
        },
      },
      'updateMask': {
        'fieldPaths': ['groupId'],
      },
      'currentDocument': {'updateTime': child['updateTime']},
    });
  }
  if (writes.isEmpty) return writes;
  writes.add({
    'update': {
      'name': parent['name'],
      'fields': {
        'version': {
          'integerValue':
              '${int.parse('${parentFields['version']['integerValue']}') + 1}',
        },
      },
    },
    'updateMask': {
      'fieldPaths': ['version'],
    },
    'currentDocument': {'updateTime': parent['updateTime']},
  });
  return writes;
}

({String projectId, String reportPath, bool apply}) migrationArguments(
  List<String> args,
) {
  if (args.length < 2 ||
      args.length > 3 ||
      args.take(2).any((value) => value.startsWith('--')) ||
      (args.length == 3 && args[2] != '--apply')) {
    throw const FormatException('プロジェクト・出力先・必要な場合だけ--applyを指定してください');
  }
  return (projectId: args[0], reportPath: args[1], apply: args.length == 3);
}

Future<void> main(List<String> args) async {
  late final ({String projectId, String reportPath, bool apply}) options;
  try {
    options = migrationArguments(args);
  } on FormatException {
    stderr.writeln(
      '使い方: dart run scripts/firebase/migrate_firestore_read_models.dart <projectId> <report.json> [--apply]',
    );
    exitCode = 1;
    return;
  }
  final token = Platform.environment['FIRESTORE_ACCESS_TOKEN'];
  if (token == null || token.isEmpty) {
    stderr.writeln('FIRESTORE_ACCESS_TOKENにOAuthアクセストークンを設定してください');
    exitCode = 1;
    return;
  }
  final client = FirestoreImportClient(options.projectId, '(default)', token);
  final report = File(options.reportPath);
  final results = <Map<String, Object?>>[];
  Future<void> save() => report.writeAsString(
    jsonEncode({
      'projectId': args[0],
      'apply': options.apply,
      'events': results,
    }),
  );
  try {
    for (final document in await client.queryDocuments('calendar_events')) {
      final data = fields(document);
      if (data['calendarFormatVersion'] == 2) continue;
      final id = (document['name'] as String).split('/').last;
      final children = await client.queryDocuments(
        'calendar_event_overrides',
        field: 'eventId',
        value: id,
      );
      final childDocuments = {
        for (final child in children)
          (child['name'] as String).split('/').last: child,
      };
      final plan = buildCalendarMigrationPlan(id, data, {
        for (final entry in childDocuments.entries)
          entry.key: fields(entry.value),
      })!;
      final result = <String, Object?>{
        'eventId': id,
        'status': '確認のみ',
        'createdEventIds': plan.independent.keys.toList(),
        'cancellations': plan.cancellations.length,
        'labelDeltas': plan.labelDeltas,
      };
      results.add(result);
      await save();
      if (!options.apply) continue;
      final labels = <String, Map<String, dynamic>>{};
      for (final id in plan.labelDeltas.keys) {
        final label = await client.read('calendar_labels', id);
        if (label == null) throw FormatException('参照中のラベルが見つかりません: $id');
        labels[id] = label;
      }
      final writes = calendarMigrationWrites(
        plan,
        document,
        childDocuments,
        labels,
        client.documentRoot,
      );
      result['status'] = '適用前';
      await save();
      await client.commit(writes);
      result['status'] = '成功';
      await save();
    }
    for (final trip in await client.queryDocuments('trip_entries')) {
      final id = (trip['name'] as String).split('/').last;
      final children = await client.queryDocuments(
        'itinerary_items',
        field: 'tripId',
        value: id,
      );
      final writes = tripChildrenGroupMigrationWrites(trip, children);
      if (writes.isEmpty) continue;
      final result = <String, Object?>{
        'tripId': id,
        'updatedItineraries': writes.length - 1,
        'status': '確認のみ',
      };
      results.add(result);
      await save();
      if (!options.apply) continue;
      result['status'] = '適用前';
      await save();
      await client.commit(writes);
      result['status'] = '成功';
      await save();
    }
    stdout.writeln(
      '対象=${results.length}、${options.apply ? '適用済み' : '確認のみ'}: ${report.path}',
    );
  } catch (error) {
    if (results.isNotEmpty) results.last['status'] = '失敗または結果不明';
    await save();
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    client.close();
  }
}
