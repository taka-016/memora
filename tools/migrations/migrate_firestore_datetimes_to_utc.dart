import 'dart:convert';
import 'dart:io';

enum DateTimeFieldKind { dateOnly, yearMonth, instant }

const targetFields = <String, Map<String, DateTimeFieldKind>>{
  'members': {'birthday': DateTimeFieldKind.dateOnly},
  'trip_entries': {
    'tripStartDate': DateTimeFieldKind.dateOnly,
    'tripEndDate': DateTimeFieldKind.dateOnly,
  },
  'pins': {
    'visitStartDate': DateTimeFieldKind.instant,
    'visitEndDate': DateTimeFieldKind.instant,
  },
  'tasks': {'dueDate': DateTimeFieldKind.dateOnly},
  'dvc_point_contracts': {
    'contractStartYearMonth': DateTimeFieldKind.yearMonth,
    'contractEndYearMonth': DateTimeFieldKind.yearMonth,
  },
  'dvc_limited_points': {
    'startYearMonth': DateTimeFieldKind.yearMonth,
    'endYearMonth': DateTimeFieldKind.yearMonth,
  },
  'dvc_point_usages': {'usageYearMonth': DateTimeFieldKind.yearMonth},
};

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  if (options.showHelp) {
    stdout.writeln(_usage);
    return;
  }

  final token = await _loadAccessToken();
  final client = _FirestoreRestClient(
    projectId: options.projectId,
    databaseId: options.databaseId,
    accessToken: token,
  );

  var scanned = 0;
  var changed = 0;
  for (final collectionEntry in targetFields.entries) {
    final docs = await client.listDocuments(collectionEntry.key);
    for (final doc in docs) {
      scanned++;
      final updates = _buildUpdates(
        doc,
        collectionEntry.value,
        options.legacyOffset,
      );
      if (updates.isEmpty) {
        continue;
      }
      changed++;
      for (final update in updates.entries) {
        stdout.writeln(
          '${options.commit ? 'UPDATE' : 'DRY-RUN'} '
          '${doc.path} ${update.key}: ${update.value.before} -> '
          '${update.value.after}',
        );
      }
      if (options.commit) {
        await client.patchDocument(doc.name, {
          for (final update in updates.entries)
            update.key: {'timestampValue': update.value.after},
        });
      }
    }
  }

  stdout.writeln(
    'scanned=$scanned changed=$changed mode=${options.commit ? 'commit' : 'dry-run'}',
  );
}

Map<String, _TimestampUpdate> _buildUpdates(
  _FirestoreDocument doc,
  Map<String, DateTimeFieldKind> fieldKinds,
  Duration legacyOffset,
) {
  final updates = <String, _TimestampUpdate>{};
  for (final fieldEntry in fieldKinds.entries) {
    final value = doc.fields[fieldEntry.key];
    if (value is! Map<String, dynamic>) {
      continue;
    }
    final timestampValue = value['timestampValue'];
    if (timestampValue is! String) {
      continue;
    }

    final normalized = _normalizeTimestamp(
      timestampValue,
      fieldEntry.value,
      legacyOffset,
    );
    if (normalized != timestampValue) {
      updates[fieldEntry.key] = _TimestampUpdate(timestampValue, normalized);
    }
  }
  return updates;
}

String _normalizeTimestamp(
  String timestampValue,
  DateTimeFieldKind kind,
  Duration legacyOffset,
) {
  final utc = DateTime.parse(timestampValue).toUtc();
  switch (kind) {
    case DateTimeFieldKind.dateOnly:
      final legacyLocal = utc.add(legacyOffset);
      return DateTime.utc(
        legacyLocal.year,
        legacyLocal.month,
        legacyLocal.day,
      ).toIso8601String();
    case DateTimeFieldKind.yearMonth:
      final legacyLocal = utc.add(legacyOffset);
      return DateTime.utc(
        legacyLocal.year,
        legacyLocal.month,
      ).toIso8601String();
    case DateTimeFieldKind.instant:
      return utc.toIso8601String();
  }
}

Future<String> _loadAccessToken() async {
  final envToken = Platform.environment['GOOGLE_OAUTH_ACCESS_TOKEN'];
  if (envToken != null && envToken.isNotEmpty) {
    return envToken;
  }

  final result = await Process.run('gcloud', [
    'auth',
    'application-default',
    'print-access-token',
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    throw StateError('Google認証トークンを取得できませんでした');
  }
  return (result.stdout as String).trim();
}

class _FirestoreRestClient {
  _FirestoreRestClient({
    required this.projectId,
    required this.databaseId,
    required this.accessToken,
  });

  final String projectId;
  final String databaseId;
  final String accessToken;

  String get _baseUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/$databaseId/documents';

  Future<List<_FirestoreDocument>> listDocuments(String collectionId) async {
    final docs = <_FirestoreDocument>[];
    String? pageToken;
    do {
      final uri = Uri.parse('$_baseUrl/$collectionId').replace(
        queryParameters: {
          'pageSize': '300',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      final response = await _request('GET', uri);
      final decoded = jsonDecode(response) as Map<String, dynamic>;
      final documents = decoded['documents'] as List<dynamic>? ?? const [];
      docs.addAll(
        documents.cast<Map<String, dynamic>>().map(_FirestoreDocument.fromJson),
      );
      pageToken = decoded['nextPageToken'] as String?;
    } while (pageToken != null && pageToken.isNotEmpty);
    return docs;
  }

  Future<void> patchDocument(
    String documentName,
    Map<String, Map<String, String>> fields,
  ) async {
    final fieldPaths = fields.keys.toList();
    final query = fieldPaths
        .map(
          (fieldPath) =>
              'updateMask.fieldPaths=${Uri.encodeQueryComponent(fieldPath)}',
        )
        .join('&');
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/$documentName?$query',
    );
    await _request('PATCH', uri, body: jsonEncode({'fields': fields}));
  }

  Future<String> _request(String method, Uri uri, {String? body}) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $accessToken',
      );
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      if (body != null) {
        request.write(body);
      }
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Firestore REST API error ${response.statusCode}: $responseBody',
        );
      }
      return responseBody;
    } finally {
      client.close();
    }
  }
}

class _FirestoreDocument {
  _FirestoreDocument({required this.name, required this.fields});

  factory _FirestoreDocument.fromJson(Map<String, dynamic> json) {
    return _FirestoreDocument(
      name: json['name'] as String,
      fields: (json['fields'] as Map<String, dynamic>?) ?? const {},
    );
  }

  final String name;
  final Map<String, dynamic> fields;

  String get path => name.split('/documents/').last;
}

class _TimestampUpdate {
  const _TimestampUpdate(this.before, this.after);

  final String before;
  final String after;
}

class _Options {
  _Options({
    required this.projectId,
    required this.databaseId,
    required this.legacyOffset,
    required this.commit,
    required this.showHelp,
  });

  final String projectId;
  final String databaseId;
  final Duration legacyOffset;
  final bool commit;
  final bool showHelp;

  factory _Options.parse(List<String> args) {
    var projectId = Platform.environment['GOOGLE_CLOUD_PROJECT'] ?? '';
    var databaseId = '(default)';
    var legacyOffset = const Duration(hours: 9);
    var commit = false;
    var showHelp = false;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
      } else if (arg == '--commit') {
        commit = true;
      } else if (arg.startsWith('--project-id=')) {
        projectId = arg.substring('--project-id='.length);
      } else if (arg.startsWith('--database-id=')) {
        databaseId = arg.substring('--database-id='.length);
      } else if (arg.startsWith('--legacy-offset=')) {
        legacyOffset = _parseOffset(arg.substring('--legacy-offset='.length));
      } else {
        throw ArgumentError('Unknown argument: $arg');
      }
    }

    if (!showHelp && projectId.isEmpty) {
      throw ArgumentError('--project-id または GOOGLE_CLOUD_PROJECT が必要です');
    }

    return _Options(
      projectId: projectId,
      databaseId: databaseId,
      legacyOffset: legacyOffset,
      commit: commit,
      showHelp: showHelp,
    );
  }
}

Duration _parseOffset(String value) {
  final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) {
    throw ArgumentError('--legacy-offset は +09:00 形式で指定してください');
  }
  final sign = match.group(1) == '-' ? -1 : 1;
  final hours = int.parse(match.group(2)!);
  final minutes = int.parse(match.group(3)!);
  return Duration(minutes: sign * ((hours * 60) + minutes));
}

const _usage = '''
Firestore日時UTC移行スクリプト

デフォルトはドライランです。更新する場合のみ --commit を付けます。

例:
  dart run tools/migrations/migrate_firestore_datetimes_to_utc.dart \\
    --project-id=your-firebase-project \\
    --legacy-offset=+09:00

  dart run tools/migrations/migrate_firestore_datetimes_to_utc.dart \\
    --project-id=your-firebase-project \\
    --legacy-offset=+09:00 \\
    --commit

認証:
  gcloud auth application-default login
  または GOOGLE_OAUTH_ACCESS_TOKEN を設定
''';
