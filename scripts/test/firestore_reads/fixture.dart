const readRegressionProjectId = 'demo-memora-read-regression';
const readRegressionDocumentRoot =
    'projects/$readRegressionProjectId/databases/(default)/documents';

Never invalid(String message) => throw FormatException(message);

Map<String, dynamic> object(Object? value, String label) =>
    value is Map && value.keys.every((key) => key is String)
    ? Map<String, dynamic>.from(value)
    : invalid('$labelはオブジェクトが必要です');

String nonEmpty(Object? value, String label) =>
    value is String && value.isNotEmpty
    ? value
    : invalid('$labelは空でない文字列が必要です');

List<dynamic> array(Object? value, String label) =>
    value is List ? value : invalid('$labelは配列が必要です');

bool isDocumentPath(String path) {
  final parts = path.split('/');
  return parts.length.isEven &&
      parts.every((part) => part.isNotEmpty && part != '.' && part != '..');
}

DateTime timestamp(Object? value) {
  final text = nonEmpty(value, '日時');
  if (!RegExp(r'T\d{2}:\d{2}:\d{2}.*(Z|[+-]\d{2}:\d{2})$').hasMatch(text)) {
    invalid('日時にはタイムゾーン付きの時刻が必要です: $text');
  }
  return DateTime.tryParse(text)?.toUtc() ?? invalid('不正な日時です: $text');
}

class ReadFixtureDocument {
  const ReadFixtureDocument(this.path, this.fields);
  final String path;
  final Map<String, dynamic> fields;
  Map<String, dynamic> get write => {
    'update': {'name': '$readRegressionDocumentRoot/$path', 'fields': fields},
  };
}

class ReadFixture {
  ReadFixture._(this.accounts, this.device, this.documents);

  final List<Map<String, dynamic>> accounts;
  final Map<String, dynamic> device;
  final List<ReadFixtureDocument> documents;

  Map<String, int> get collectionCounts {
    final counts = <String, int>{};
    for (final doc in documents) {
      final collection = doc.path.split('/').first;
      counts[collection] = (counts[collection] ?? 0) + 1;
    }
    return counts;
  }

  static ReadFixture parse(Map<String, dynamic> source) {
    if (source['version'] != 1) invalid('未対応のデータ形式です');
    final accounts = array(
      source['accounts'],
      'accounts',
    ).map((entry) => object(entry, 'account')).toList();
    final ids = <String>{};
    final emails = <String>{};
    for (final account in accounts) {
      final id = nonEmpty(account['id'], 'account.id');
      final email = nonEmpty(account['email'], 'account.email');
      final password = nonEmpty(account['password'], 'account.password');
      if (!ids.add(id) ||
          !emails.add(email) ||
          !email.contains('@') ||
          password.length < 6 ||
          account['emailVerified'] is! bool) {
        invalid('認証アカウントが不正または重複しています: $id');
      }
    }
    final device = object(source['device'], 'device');
    object(device['preferences'], 'device.preferences');
    array(device['widgets'], 'device.widgets');
    if (!['granted', 'denied'].contains(device['notificationPermission'])) {
      invalid('通知権限はgrantedかdeniedを指定してください');
    }
    final expanded = <Map<String, dynamic>>[];
    for (final entry in array(source['documents'], 'documents')) {
      final doc = object(entry, 'document');
      final repeat = doc['repeat'] == null
          ? <String, dynamic>{}
          : object(doc['repeat'], 'repeat');
      var bindings = <Map<String, Object?>>[{}];
      for (final axis in repeat.entries) {
        final values = array(axis.value, 'repeat.${axis.key}');
        if (values.isEmpty) invalid('繰り返しには値が必要です');
        bindings = [
          for (final binding in bindings)
            for (final value in values) {...binding, axis.key: value},
        ];
      }
      for (final binding in bindings) {
        expanded.add(
          object(
            _substitute({
              'path': doc['path'],
              'fields': doc['fields'],
            }, binding),
            'document',
          ),
        );
      }
    }
    final paths = <String>{};
    for (final doc in expanded) {
      final path = nonEmpty(doc['path'], 'document.path');
      if (!isDocumentPath(path) || !paths.add(path)) {
        invalid('文書パスが不正または重複しています: $path');
      }
    }
    return ReadFixture._(accounts, device, [
      for (final doc in expanded)
        ReadFixtureDocument(doc['path'] as String, {
          for (final field in object(doc['fields'], 'fields').entries)
            field.key: _encode(field.value, paths),
        }),
    ]);
  }

  static Object? _substitute(Object? value, Map<String, Object?> variables) {
    if (value is String) {
      final expression = RegExp(r'\$\{([^}]+)\}');
      final full = expression.firstMatch(value);
      if (full != null && full.group(0) == value) {
        final key = full.group(1)!;
        if (!variables.containsKey(key)) invalid('未定義の変数です: $key');
        return variables[key];
      }
      return value.replaceAllMapped(expression, (match) {
        final key = match.group(1)!;
        if (!variables.containsKey(key)) invalid('未定義の変数です: $key');
        return variables[key].toString();
      });
    }
    if (value is List)
      return value.map((v) => _substitute(v, variables)).toList();
    if (value is Map<String, dynamic>) {
      return value.map((key, v) => MapEntry(key, _substitute(v, variables)));
    }
    return value;
  }

  static Map<String, dynamic> _encode(Object? value, Set<String> paths) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double && value.isFinite) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is List)
      return {
        'arrayValue': {'values': value.map((v) => _encode(v, paths)).toList()},
      };
    if (value is Map<String, dynamic>) {
      if (value.containsKey(r'$timestamp')) {
        if (value.length != 1) invalid('日時指定に余分なフィールドがあります');
        return {
          'timestampValue': timestamp(value[r'$timestamp']).toIso8601String(),
        };
      }
      if (value.containsKey(r'$reference')) {
        final path = nonEmpty(value[r'$reference'], 'reference');
        if (value.length != 1 || !paths.contains(path))
          invalid('参照先がありません: $path');
        return {'referenceValue': '$readRegressionDocumentRoot/$path'};
      }
      if (value.keys.any((key) => key.startsWith(r'$'))) invalid('未対応の型指定です');
      return {
        'mapValue': {
          'fields': value.map((key, v) => MapEntry(key, _encode(v, paths))),
        },
      };
    }
    return invalid('未対応の値です: $value');
  }
}
