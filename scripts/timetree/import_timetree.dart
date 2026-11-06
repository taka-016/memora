import 'dart:convert';
import 'dart:io';

import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/domain/entities/calendar/calendar_event.dart';
import 'package:memora/domain/entities/calendar/calendar_label.dart';
import 'package:memora/infrastructure/services/iana_calendar_time_zone.dart';
import 'package:memora/infrastructure/services/validate_calendar_recurrence.dart';
import 'package:uuid/uuid.dart';

Map<String, dynamic> _map(Object? value) =>
    (value as Map).cast<String, dynamic>();
String _required(Map<String, dynamic> value, String key) {
  final text = value[key];
  if (text is! String || text.trim().isEmpty) {
    throw FormatException('$keyを指定してください');
  }
  return text;
}

String _documentId(String value) {
  if (value.contains('/') || value == '.' || value == '..') {
    throw const FormatException('ドキュメントIDにパスは指定できません');
  }
  return value;
}

String _mappingKey(String? category, String color) =>
    jsonEncode([category, color.toUpperCase()]);

class TimeTreeImportConfig {
  TimeTreeImportConfig.fromJson(Map<String, dynamic> value)
    : projectId = _required(value, 'projectId'),
      databaseId = _required(value, 'databaseId'),
      groupId = _documentId(_required(value, 'groupId')),
      inputIcs = _required(value, 'inputIcs'),
      reportPath = _required(value, 'reportPath'),
      accessTokenEnvironmentVariable = _required(
        value,
        'accessTokenEnvironmentVariable',
      ),
      allDayExceptionTimeZone = _required(value, 'allDayExceptionTimeZone'),
      labels = _map(value['labels']) {
    if (!RegExp(r'^[a-z][a-z0-9-]+$').hasMatch(projectId) ||
        databaseId.contains('/')) {
      throw const FormatException('FirebaseプロジェクトまたはデータベースIDが不正です');
    }
    for (final item in value['mappings'] as List) {
      final row = _map(item);
      final category = row['category'] as String?;
      final key = _mappingKey(category, _required(row, 'color'));
      final label = _required(row, 'label');
      if (mappings.containsKey(key) || !labels.containsKey(label)) {
        throw const FormatException('分類・色の重複または未定義のラベル対応があります');
      }
      mappings[key] = label;
    }
  }
  final String projectId;
  final String databaseId;
  final String groupId;
  final String inputIcs;
  final String reportPath;
  final String accessTokenEnvironmentVariable;
  final String allDayExceptionTimeZone;
  final Map<String, dynamic> labels;
  final Map<String, String> mappings = {};
}

class _ImportLabel {
  _ImportLabel(
    String key,
    Map<String, dynamic> value,
    String groupId,
    String Function() newId,
  ) : type = _required(value, 'type'),
      memberId = value['memberId'] as String? ?? '',
      id = value['new'] != null ? newId() : value['id'] as String? ?? '' {
    if (type == 'custom') {
      _documentId(id);
      if (id.isEmpty || (value['new'] != null && value['id'] != null)) {
        throw FormatException('ラベル$keyは既存IDまたは新規定義のいずれかを指定してください');
      }
      if (value['new'] != null) {
        final definition = _map(value['new']);
        created = CalendarLabel(
          id: id,
          groupId: groupId,
          name: _required(definition, 'name'),
          color: _required(definition, 'color'),
          textColor: _required(definition, 'textColor'),
          sortOrder: definition['sortOrder'] as int,
        );
      }
    } else if (type != 'group' && type != 'member' ||
        type == 'member' && memberId.trim().isEmpty) {
      throw FormatException('ラベル$keyの種別またはメンバーIDが不正です');
    }
  }
  final String type;
  final String memberId;
  final String id;
  CalendarLabel? created;
  Map<String, Object?> report() => {
    'type': type,
    if (type == 'custom') 'id': id,
    if (type == 'member') 'memberId': memberId,
    if (created case final label?)
      'new': {
        'name': label.name,
        'color': label.color,
        'textColor': label.textColor,
        'sortOrder': label.sortOrder,
      },
  };
}

class TimeTreeImportEvent {
  TimeTreeImportEvent(
    this.event,
    this.createdAt,
    this.updatedAt,
    this._uid,
    this.labelKey,
  );
  final CalendarEvent event;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String _uid;
  final String labelKey;
  Map<String, Object?> document() => {
    'groupId': event.groupId,
    'title': event.title,
    'labelId': event.labelType == 'custom' ? event.labelId : null,
    'labelType': event.labelType,
    'memberId': event.labelType == 'member' ? event.memberId : null,
    'url': event.url,
    'memo': event.memo,
    'locationName': event.locationName,
    'latitude': event.latitude,
    'longitude': event.longitude,
    'startDateTime': event.startDateTime,
    'endDateTime': event.endDateTime,
    'isAllDay': event.isAllDay,
    'notificationMinutesBefore': event.notificationMinutesBefore,
    'recurrenceRule': event.recurrenceRule,
    'timeZone': event.timeZone,
    'referencedLabelIds': [if (event.labelType == 'custom') event.labelId],
    'overrideIds': <String>[],
    'version': 1,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class TimeTreeImportPlan {
  TimeTreeImportPlan(this.config, this._labels);
  final TimeTreeImportConfig config;
  final Map<String, _ImportLabel> _labels;
  final List<TimeTreeImportEvent> events = [];
  final List<Map<String, Object?>> excluded = [];
  final List<Map<String, Object?>> failures = [];
  final List<Map<String, Object?>> manualCorrections = [];
  final List<Map<String, Object?>> normalizations = [];
  Map<String, Object?> report() => {
    'projectId': config.projectId,
    'databaseId': config.databaseId,
    'groupId': config.groupId,
    'counts': {
      'ready': events.length,
      'failed': failures.length,
      'excluded': excluded.length,
    },
    'labels': {
      for (final key in events.map((v) => v.labelKey).toSet())
        key: _labels[key]!.report(),
    },
    'events': [
      for (final value in events)
        {
          'eventId': value.event.id,
          'label': value.labelKey,
          ..._jsonDates(value.document()),
        },
    ],
    'failures': failures,
    'excluded': excluded,
    'manualCorrections': manualCorrections,
    'normalizations': normalizations,
  };
}

Map<String, Object?> _jsonDates(Map<String, Object?> map) => map.map(
  (key, value) => MapEntry(
    key,
    value is DateTime ? value.toUtc().toIso8601String() : value,
  ),
);

class _Property {
  _Property(this.value, this.parameters);
  final String value;
  final Map<String, String> parameters;
}

class _SourceEvent {
  final Map<String, List<_Property>> properties = {};
  _Property? property(String name) => properties[name]?.single;
  String text(String name) => _unescape(property(name)?.value ?? '');
}

String _unescape(String text) => text.replaceAllMapped(
  RegExp(r'\\([nN,;\\])'),
  (match) => switch (match[1]) {
    'n' || 'N' => '\n',
    _ => match[1]!,
  },
);

List<_SourceEvent> _parse(String ics) {
  final lines = ics
      .replaceAll(RegExp(r'\r?\n[ \t]'), '')
      .split(RegExp(r'\r?\n'));
  if (!lines.contains('BEGIN:VCALENDAR') || !lines.contains('END:VCALENDAR')) {
    throw const FormatException('VCALENDARが見つからないか途中で切れています');
  }
  final events = <_SourceEvent>[];
  _SourceEvent? current;
  var alarm = false;
  for (final line in lines) {
    if (line == 'BEGIN:VEVENT') {
      if (current != null) throw const FormatException('VEVENTが入れ子です');
      current = _SourceEvent();
    } else if (line == 'END:VEVENT') {
      if (current == null || alarm) {
        throw const FormatException('VEVENTまたはVALARMが不正です');
      }
      events.add(current);
      current = null;
    } else if (current != null && line == 'BEGIN:VALARM') {
      alarm = true;
    } else if (current != null && line == 'END:VALARM') {
      alarm = false;
    } else if (current != null && !alarm && line.isNotEmpty) {
      final colon = line.indexOf(':');
      if (colon < 1) throw const FormatException('ICSの属性行が不正です');
      final fields = line.substring(0, colon).split(';');
      final parameters = <String, String>{};
      for (final parameter in fields.skip(1)) {
        final separator = parameter.indexOf('=');
        if (separator < 1) throw const FormatException('ICSのパラメーターが不正です');
        parameters[parameter.substring(0, separator)] = parameter
            .substring(separator + 1)
            .replaceAll('"', '');
      }
      (current.properties[fields.first] ??= []).add(
        _Property(line.substring(colon + 1), parameters),
      );
    }
  }
  if (current != null) throw const FormatException('VEVENTが途中で切れています');
  return events;
}

class _Date {
  _Date(this.value, this.allDay, this.zone);
  final DateTime value;
  final bool allDay;
  final String? zone;
}

_Date _date(_Property? property, IanaCalendarTimeZone zones) {
  if (property == null) throw const FormatException('必須の日時がありません');
  final text = property.value;
  final allDay = RegExp(r'^\d{8}$').hasMatch(text);
  if (!allDay && !RegExp(r'^\d{8}T\d{6}Z?$').hasMatch(text) ||
      property.parameters['VALUE'] == 'DATE' && !allDay) {
    throw FormatException('日時の形式が不正です: $text');
  }
  final parsed = DateTime.tryParse(
    allDay || text.endsWith('Z') ? text : '${text}Z',
  );
  if (parsed == null ||
      _dateDigits(parsed) != text.substring(0, 8) ||
      !allDay &&
          '${_two(parsed.hour)}${_two(parsed.minute)}${_two(parsed.second)}' !=
              text.substring(9, 15)) {
    throw FormatException('存在しない日時です: $text');
  }
  if (allDay) {
    return _Date(
      DateTime.utc(parsed.year, parsed.month, parsed.day),
      true,
      null,
    );
  }
  if (text.endsWith('Z')) return _Date(parsed.toUtc(), false, 'Etc/UTC');
  final zone = property.parameters['TZID'];
  if (zone == null) throw const FormatException('時刻付き日時のタイムゾーンがありません');
  final resolved = zones.resolve(parsed, zone);
  if (resolved == null) throw const FormatException('タイムゾーン内に存在しない時刻です');
  return _Date(resolved.toUtc(), false, zone);
}

String _two(int value) => value.toString().padLeft(2, '0');
String _dateDigits(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}${_two(value.month)}${_two(value.day)}';
DateTime _metadataDate(
  _SourceEvent source,
  String key,
  IanaCalendarTimeZone zones,
) {
  final property = source.property(key);
  if (property == null || !RegExp(r'^\d{8}T\d{6}Z$').hasMatch(property.value)) {
    throw FormatException('$keyはUTCの日時が必須です');
  }
  return _date(property, zones).value;
}

Map<String, Object?> _content(_SourceEvent source, IanaCalendarTimeZone zones) {
  final start = _date(source.property('DTSTART'), zones);
  final end = _date(source.property('DTEND'), zones);
  if (start.allDay != end.allDay ||
      end.value.isBefore(start.value) ||
      start.allDay && !end.value.isAfter(start.value)) {
    throw const FormatException('予定の期間または終日区分が不正です');
  }
  double? latitude;
  double? longitude;
  final geo = source.property('GEO');
  if (geo != null) {
    final values = geo.value.split(';');
    if (values.length != 2) throw const FormatException('座標の形式が不正です');
    latitude = double.parse(values[0]);
    longitude = double.parse(values[1]);
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw const FormatException('座標の範囲が不正です');
    }
  }
  return {
    'title': source.text('SUMMARY'),
    'startDateTime': start.value,
    'endDateTime': end.value,
    'isAllDay': start.allDay,
    'timeZone': start.zone,
    'memo': source.text('DESCRIPTION'),
    'locationName': source.text('LOCATION'),
    'url': source.text('URL'),
    'latitude': latitude,
    'longitude': longitude,
  };
}

String? _rule(_SourceEvent source) {
  final raw = source.property('RRULE')?.value;
  if (raw == null) return null;
  final parts = raw.split(';');
  final wkst = parts.where((v) => v.startsWith('WKST=')).toList();
  if (wkst.isNotEmpty) {
    final frequency = parts.where((v) => v.startsWith('FREQ=')).single;
    final interval = parts.where((v) => v.startsWith('INTERVAL=')).firstOrNull;
    if (wkst.length != 1 ||
        !RegExp(r'^WKST=(MO|TU|WE|TH|FR|SA|SU)$').hasMatch(wkst.single) ||
        !(frequency == 'FREQ=MONTHLY' ||
            frequency == 'FREQ=YEARLY' ||
            frequency == 'FREQ=WEEKLY' &&
                (interval == null || interval == 'INTERVAL=1'))) {
      throw const FormatException('発生日を維持してWKSTを除去できません');
    }
  }
  return parts.where((v) => !v.startsWith('WKST=')).join(';');
}

TimeTreeImportPlan buildTimeTreeImportPlan(
  String ics,
  TimeTreeImportConfig config, {
  String Function()? newId,
}) {
  final allocate = newId ?? const Uuid().v4;
  final labels = {
    for (final entry in config.labels.entries)
      entry.key: _ImportLabel(
        entry.key,
        _map(entry.value),
        config.groupId,
        allocate,
      ),
  };
  final plan = TimeTreeImportPlan(config, labels);
  final sources = _parse(ics);
  final zones = IanaCalendarTimeZone();
  final related = <String, List<Map<String, Object?>>>{};
  final sourceByUid = <String, _SourceEvent>{};
  for (var index = 0; index < sources.length; index++) {
    final source = sources[index];
    try {
      final uid = source.text('UID');
      if (uid.isEmpty) throw const FormatException('関連情報の参照に必要なUIDがありません');
      if (sourceByUid.containsKey(uid)) {
        throw const FormatException('関連情報を一意に参照できません');
      }
      sourceByUid[uid] = source;
      if (source.property('RECURRENCE-ID') != null) {
        throw const FormatException('RECURRENCE-IDには対応していません');
      }
      final content = _content(source, zones);
      final parent = source.text('RELATED-TO');
      if (parent.isNotEmpty) {
        final record = {
          'sourceIndex': index + 1,
          ..._jsonDates(content),
          'reason': 'RELATED-TO付きの別予定は取り込まず手修正用に出力',
        };
        plan.excluded.add(record);
        (related[parent] ??= []).add(record);
        continue;
      }
      final category = source.text('CATEGORIES');
      final color = source.text('COLOR');
      final key = config
          .mappings[_mappingKey(category.isEmpty ? null : category, color)];
      if (key == null) {
        throw FormatException(
          'ラベル対応がありません: 分類=${category.isEmpty ? '分類なし' : category}、色=$color',
        );
      }
      final label = labels[key]!;
      final recurrence = _rule(source);
      final allDay = content['isAllDay'] as bool;
      final event = CalendarEvent(
        id: allocate(),
        groupId: config.groupId,
        labelId: label.type == 'custom' ? label.id : '',
        labelType: label.type,
        memberId: label.memberId,
        title: content['title'] as String,
        startDateTime: content['startDateTime'] as DateTime,
        endDateTime: content['endDateTime'] as DateTime,
        isAllDay: allDay,
        memo: content['memo'] as String,
        locationName: content['locationName'] as String,
        url: content['url'] as String,
        latitude: content['latitude'] as double?,
        longitude: content['longitude'] as double?,
        recurrenceRule: recurrence,
        timeZone: recurrence != null && !allDay
            ? content['timeZone'] as String
            : null,
        notificationMinutesBefore: allDay
            ? const CalendarNotificationPreferences().allDay
            : const CalendarNotificationPreferences().timed,
      );
      validateCalendarRecurrence(event);
      final value = TimeTreeImportEvent(
        event,
        _metadataDate(source, 'CREATED', zones),
        _metadataDate(source, 'LAST-MODIFIED', zones),
        uid,
        key,
      );
      plan.events.add(value);
      if (recurrence != source.property('RRULE')?.value) {
        plan.normalizations.add({
          'eventId': event.id,
          'title': event.title,
          'originalRule': source.text('RRULE'),
          'storedRule': recurrence,
          'reason': '発生日を変えないWKSTを除去',
        });
      }
    } catch (error) {
      plan.failures.add({
        'sourceIndex': index + 1,
        'title': source.text('SUMMARY'),
        'reason': error.toString(),
      });
    }
  }
  for (final value in plan.events) {
    final source = sourceByUid[value._uid]!;
    final dates = <String>[];
    try {
      for (final property in source.properties['EXDATE'] ?? <_Property>[]) {
        for (final text in property.value.split(',')) {
          final date = _date(_Property(text, property.parameters), zones);
          if (value.event.isAllDay) {
            final local = date.allDay
                ? date.value
                : zones.local(date.value, config.allDayExceptionTimeZone);
            dates.add(
              '${local.year.toString().padLeft(4, '0')}-${_two(local.month)}-${_two(local.day)}',
            );
          } else {
            dates.add(date.value.toUtc().toIso8601String());
          }
        }
      }
    } catch (error) {
      plan.failures.add({
        'title': value.event.title,
        'reason': '除外日の出力に失敗しました: $error',
      });
    }
    if (dates.isNotEmpty || related.containsKey(value._uid)) {
      plan.manualCorrections.add({
        'title': value.event.title,
        'eventId': value.event.id,
        'excludedDates': dates,
        'exceptionTimeZone':
            value.event.timeZone ?? config.allDayExceptionTimeZone,
        'relatedEvents': related.remove(value._uid) ?? [],
        'reason': '取消し・個別回の変更はアプリで手修正してください。変更元の回は推測していません',
      });
    }
  }
  for (final records in related.values) {
    plan.manualCorrections.add({
      'eventId': null,
      'relatedEvents': records,
      'reason': '取り込み対象の親系列が見つかりません',
    });
  }
  return plan;
}

Map<String, Object?> _firestoreValue(Object? value) => switch (value) {
  null => {'nullValue': null},
  String() => {'stringValue': value},
  bool() => {'booleanValue': value},
  int() => {'integerValue': '$value'},
  double() => {'doubleValue': value},
  DateTime() => {'timestampValue': value.toUtc().toIso8601String()},
  List() => {
    'arrayValue': {'values': value.map(_firestoreValue).toList()},
  },
  _ => throw const FormatException('保存できない値です'),
};
Map<String, Object?> _fields(Map<String, Object?> values) =>
    values.map((key, value) => MapEntry(key, _firestoreValue(value)));

class FirestoreImportRejected implements Exception {
  FirestoreImportRejected(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class FirestoreImportOutcomeUnknown implements Exception {
  @override
  String toString() =>
      'Commitの応答を確認できませんでした。全件成功または全件未登録のいずれかです。再実行せず、事前レポートの予定IDで登録結果を確認してください';
}

class FirestoreImportClient {
  FirestoreImportClient(
    this.projectId,
    this.databaseId,
    this._token, {
    Uri? endpoint,
  }) : _endpoint = endpoint ?? Uri.parse('https://firestore.googleapis.com');
  final String projectId;
  final String databaseId;
  final String _token;
  final Uri _endpoint;
  final HttpClient _http = HttpClient();
  String get documentRoot =>
      'projects/$projectId/databases/$databaseId/documents';
  Future<Object?> _request(
    String method,
    String suffix, [
    Map<String, Object?>? body,
  ]) async {
    final uri = _endpoint.replace(path: '/v1/$documentRoot$suffix');
    final request = await _http.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_token');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode == 404 && method == 'GET') return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FirestoreImportRejected(
        'Firestoreが要求を拒否しました（HTTP ${response.statusCode}）: $text',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(text);
  }

  Future<Map<String, dynamic>?> read(String collection, String id) async {
    final value = await _request('GET', '/$collection/${_documentId(id)}');
    return value == null ? null : _map(value);
  }

  Future<Set<String>> groupMemberIds(String groupId) async {
    final rows = await _request('POST', ':runQuery', {
      'structuredQuery': {
        'from': [
          {'collectionId': 'group_members'},
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'groupId'},
            'op': 'EQUAL',
            'value': {'stringValue': groupId},
          },
        },
      },
    }) as List;
    return {
      for (final row in rows)
        if (row['document'] != null)
          row['document']['fields']['memberId']['stringValue'] as String,
    };
  }

  Future<void> commit(List<Map<String, Object?>> writes) async {
    final body = {'writes': writes};
    if (utf8.encode(jsonEncode(body)).length > 10 * 1024 * 1024) {
      throw const FormatException('Commitの上限10MiBを超えています。分割せず書き込みを中止しました');
    }
    try {
      await _request('POST', ':commit', body);
    } on FirestoreImportRejected catch (error) {
      if (error.statusCode == 408 || (error.statusCode ?? 0) >= 500) {
        throw FirestoreImportOutcomeUnknown();
      }
      rethrow;
    } catch (_) {
      throw FirestoreImportOutcomeUnknown();
    }
  }

  void close() => _http.close(force: true);
}

Future<void> applyTimeTreeImportPlan(
  TimeTreeImportPlan plan,
  FirestoreImportClient client,
) async {
  if (plan.failures.isNotEmpty || plan.events.isEmpty) {
    throw const FormatException('変換失敗があるか取り込み対象がありません。書き込みは行っていません');
  }
  if (client.projectId != plan.config.projectId ||
      client.databaseId != plan.config.databaseId) {
    throw const FormatException('接続先と設定のプロジェクトが一致しません');
  }
  if (await client.read('groups', plan.config.groupId) == null) {
    throw const FormatException('取り込み先グループが存在しません');
  }
  final memberIds = plan.events
      .where((value) => value.event.labelType == 'member')
      .map((value) => value.event.memberId)
      .toSet();
  if (memberIds.isNotEmpty) {
    final groupMembers = await client.groupMemberIds(plan.config.groupId);
    for (final memberId in memberIds) {
      if (!groupMembers.contains(memberId) ||
          await client.read('members', memberId) == null) {
        throw const FormatException('メンバーのラベルには取り込み先グループに所属中のメンバーを指定してください');
      }
    }
  }
  final writes = <Map<String, Object?>>[];
  final uses = <String, int>{};
  final usedLabels = <String, _ImportLabel>{};
  for (final event in plan.events) {
    final label = plan._labels[event.labelKey]!;
    if (label.type == 'custom') {
      uses.update(label.id, (value) => value + 1, ifAbsent: () => 1);
      usedLabels[label.id] = label;
    }
    writes.add({
      'update': {
        'name': '${client.documentRoot}/calendar_events/${event.event.id}',
        'fields': _fields(event.document()),
      },
      'currentDocument': {'exists': false},
    });
  }
  for (final entry in uses.entries) {
    final label = usedLabels[entry.key]!;
    final name = '${client.documentRoot}/calendar_labels/${entry.key}';
    final created = label.created;
    if (created != null) {
      writes.add({
        'update': {
          'name': name,
          'fields': _fields({
            'groupId': created.groupId,
            'name': created.name,
            'color': created.color,
            'textColor': created.textColor,
            'sortOrder': created.sortOrder,
            'version': 1,
            'eventCount': entry.value,
          }),
        },
        'currentDocument': {'exists': false},
        'updateTransforms': [
          for (final field in ['createdAt', 'updatedAt'])
            {'fieldPath': field, 'setToServerValue': 'REQUEST_TIME'},
        ],
      });
    } else {
      final snapshot = await client.read('calendar_labels', label.id);
      final fields = snapshot?['fields'] as Map?;
      if (fields == null ||
          fields['groupId']?['stringValue'] != plan.config.groupId) {
        throw const FormatException('同じグループの既存ラベルを指定してください');
      }
      final count = int.tryParse(
        fields['eventCount']?['integerValue']?.toString() ?? '',
      );
      if (count == null) throw const FormatException('既存ラベルの利用件数が不正です');
      writes.add({
        'update': {
          'name': name,
          'fields': _fields({'eventCount': count + entry.value}),
        },
        'updateMask': {
          'fieldPaths': ['eventCount'],
        },
        'currentDocument': {'updateTime': snapshot!['updateTime']},
      });
    }
  }
  await client.commit(writes);
}

Future<void> executeTimeTreeImport(
  TimeTreeImportPlan plan,
  FirestoreImportClient client, {
  required Future<void> Function(String status) saveReport,
  required void Function(String message) output,
}) async {
  await saveReport('実行中');
  await applyTimeTreeImportPlan(plan, client);
  try {
    await saveReport('成功');
  } catch (error) {
    output(
      'Firestoreへの登録は成功しましたがレポートを保存できませんでした。再実行しないでください。事前レポートの予定IDを確認してください: $error',
    );
  }
  output(
    '成功=${plan.events.length}、失敗=0、除外=${plan.excluded.length}。手修正事項はレポートを確認してください',
  );
}

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    stdout.writeln(
      '使用方法: dart run scripts/timetree/import_timetree.dart 設定.json [--apply]\n既定は確認のみ。--applyではレポート出力後に「取り込む」と入力した場合だけ書き込みます。',
    );
    return;
  }
  TimeTreeImportPlan? plan;
  File? report;
  try {
    if (args.length > 2 || args.skip(1).any((value) => value != '--apply')) {
      throw const FormatException('不明な引数です');
    }
    final configFile = File(args.first).absolute;
    final config = TimeTreeImportConfig.fromJson(
      _map(jsonDecode(await configFile.readAsString())),
    );
    File relative(String path) =>
        File.fromUri(configFile.parent.uri.resolve(path));
    report = relative(config.reportPath);
    if (report.absolute.path == relative(config.inputIcs).absolute.path ||
        report.absolute.path == configFile.path) {
      throw const FormatException('レポート出力先をICS・設定ファイルとは別にしてください');
    }
    plan = buildTimeTreeImportPlan(
      await relative(config.inputIcs).readAsString(),
      config,
    );
    Future<void> save(String status, {String? reason}) => report!.writeAsString(
      jsonEncode({...plan!.report(), 'status': status, 'reason': ?reason}),
    );
    await save('確認のみ');
    stdout.writeln(
      'プロジェクト=${config.projectId}、DB=${config.databaseId}、グループ=${config.groupId}\n取り込み対象=${plan.events.length}、失敗=${plan.failures.length}、除外=${plan.excluded.length}\n変換内容・ラベル対応・手修正事項: ${report.path}',
    );
    if (plan.failures.isNotEmpty) {
      for (final failure in plan.failures) {
        stderr.writeln(failure['reason']);
      }
      exitCode = 1;
      return;
    }
    if (!args.contains('--apply')) return;
    final token = Platform.environment[config.accessTokenEnvironmentVariable];
    if (token == null || token.trim().isEmpty) {
      throw FormatException(
        '${config.accessTokenEnvironmentVariable}にOAuthアクセストークンを設定してください',
      );
    }
    stdout.write('レポートを確認し、登録する場合は「取り込む」と入力してください: ');
    if (stdin.readLineSync() != '取り込む') {
      stdout.writeln('中止しました。書き込みは行っていません');
      return;
    }
    final client = FirestoreImportClient(
      config.projectId,
      config.databaseId,
      token,
    );
    try {
      await executeTimeTreeImport(
        plan,
        client,
        saveReport: save,
        output: stdout.writeln,
      );
    } finally {
      client.close();
    }
  } catch (error) {
    final unknown = error is FirestoreImportOutcomeUnknown;
    if (plan != null && report != null) {
      try {
        await report.writeAsString(
          jsonEncode({
            ...plan.report(),
            'status': unknown ? '結果不明' : '失敗',
            'reason': error.toString(),
          }),
        );
      } catch (reportError) {
        stderr.writeln('レポートを保存できませんでした: $reportError');
      }
    }
    stderr.writeln(
      '成功=0、${unknown ? '結果不明' : '失敗'}=${plan?.events.length ?? 0}、除外=${plan?.excluded.length ?? 0}: $error',
    );
    exitCode = 1;
  }
}
