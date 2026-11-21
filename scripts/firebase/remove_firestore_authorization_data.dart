import 'dart:convert';
import 'dart:io';

import '../timetree/import_timetree.dart' show FirestoreImportClient;
import 'migrate_firestore_read_models.dart' show migrationArguments;

const obsoleteAuthorizationCollections = [
  'account_permissions',
  'member_invitation_claims',
];

const _obsoleteMemberFields = ['groupIds', 'managedGroupIds', 'changedGroupId'];

List<Map<String, Object?>> authorizationCleanupWrites({
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> obsolete,
}) {
  final writes = <Map<String, Object?>>[];
  for (final member in members) {
    final fields = member['fields'] as Map? ?? const {};
    final fieldPaths = _obsoleteMemberFields.where(fields.containsKey).toList();
    if (fieldPaths.isEmpty) continue;

    writes.add({
      'update': {'name': member['name'] as String},
      'updateMask': {'fieldPaths': fieldPaths},
      'currentDocument': {'updateTime': member['updateTime'] as String},
    });
  }
  for (final document in obsolete) {
    writes.add({
      'delete': document['name'] as String,
      'currentDocument': {'updateTime': document['updateTime'] as String},
    });
  }
  return writes;
}

Future<void> main(List<String> args) async {
  late final ({String projectId, String reportPath, bool apply}) options;
  try {
    options = migrationArguments(args);
  } on FormatException {
    stderr.writeln(
      '使い方: dart run scripts/firebase/remove_firestore_authorization_data.dart <projectId> <report.json> [--apply]',
    );
    exitCode = 64;
    return;
  }

  final token = Platform.environment['FIRESTORE_ACCESS_TOKEN'];
  if (token == null || token.isEmpty) {
    stderr.writeln('FIRESTORE_ACCESS_TOKENにOAuthアクセストークンを設定してください');
    exitCode = 1;
    return;
  }

  final client = FirestoreImportClient(options.projectId, '(default)', token);
  final report = <String, Object?>{
    'projectId': options.projectId,
    'apply': options.apply,
    'status': '確認中',
    'appliedDocuments': 0,
  };
  final reportFile = File(options.reportPath);
  Future<void> saveReport() => reportFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );

  try {
    final members = await client.queryDocuments('members');
    final obsolete = [
      for (final name in obsoleteAuthorizationCollections)
        ...await client.queryDocuments(name),
    ];
    final writes = authorizationCleanupWrites(
      members: members,
      obsolete: obsolete,
    );
    report['documents'] = [
      for (final write in writes)
        (write['update'] as Map?)?['name'] ?? write['delete'],
    ];
    report['status'] = options.apply ? '適用中' : '確認のみ';
    await saveReport();
    if (options.apply) {
      for (var offset = 0; offset < writes.length; offset += 200) {
        final batch = writes.skip(offset).take(200).toList();
        await client.commit(batch);
        report['appliedDocuments'] = offset + batch.length;
        await saveReport();
      }
      report['status'] = '適用済み';
      await saveReport();
    }
    stdout.writeln('対象=${writes.length}: ${options.reportPath}');
  } catch (error) {
    report['status'] = '失敗または結果不明';
    report['error'] = error.toString();
    await saveReport();
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    client.close();
  }
}
