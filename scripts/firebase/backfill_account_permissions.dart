import 'dart:convert';
import 'dart:io';

import '../timetree/import_timetree.dart' show FirestoreImportClient;
import 'migrate_firestore_read_models.dart'
    show encode, fields, migrationArguments;

class AccountPermissionsPlan {
  const AccountPermissionsPlan(this.documents, this.issues);

  final Map<String, Map<String, Object?>> documents;
  final List<String> issues;
}

AccountPermissionsPlan buildAccountPermissionsPlan({
  required Map<String, Map<String, Object?>> members,
  required Map<String, Map<String, Object?>> groups,
  required Map<String, Map<String, Object?>> memberships,
  required Map<String, Map<String, Object?>> existing,
}) {
  final issues = <String>[];
  final accounts = <String, List<String>>{};
  for (final entry in members.entries) {
    final accountId = entry.value['accountId'];
    if (accountId is String && accountId.isNotEmpty) {
      accounts.putIfAbsent(accountId, () => []).add(entry.key);
    }
  }
  final memberGroups = <String, Set<String>>{};
  final managedGroups = <String, Set<String>>{};
  for (final entry in memberships.entries) {
    final groupId = entry.value['groupId'];
    final memberId = entry.value['memberId'];
    if (groupId is! String ||
        memberId is! String ||
        !groups.containsKey(groupId) ||
        !members.containsKey(memberId)) {
      continue;
    }
    final ids = memberGroups.putIfAbsent(memberId, () => {});
    if (!ids.add(groupId)) {
      issues.add('重複所属: ${entry.key} ($groupId / $memberId)');
    }
    if (entry.value['isAdministrator'] == true ||
        groups[groupId]!['ownerId'] == memberId) {
      managedGroups.putIfAbsent(memberId, () => {}).add(groupId);
    }
  }
  for (final entry in groups.entries) {
    final ownerId = entry.value['ownerId'];
    if (!(memberGroups[ownerId]?.contains(entry.key) ?? false)) {
      issues.add('所有者の有効な所属が存在しない: ${entry.key} / $ownerId');
    }
  }
  final documents = <String, Map<String, Object?>>{};
  for (final entry in accounts.entries) {
    if (entry.value.length != 1) {
      issues.add('アカウントと本人の重複対応: ${entry.key} / ${entry.value.join(', ')}');
      continue;
    }
    final memberId = entry.value.single;
    final desired = <String, Object?>{
      'memberId': memberId,
      'memberGroupIds': (memberGroups[memberId] ?? {}).toList()..sort(),
      'managedGroupIds': (managedGroups[memberId] ?? {}).toList()..sort(),
    };
    documents[entry.key] = desired;
    final current = existing[entry.key];
    if (current != null && !_samePermissions(current, desired)) {
      issues.add('既存の認可文書と不一致: ${entry.key}');
    }
  }
  for (final accountId in existing.keys) {
    if (!accounts.containsKey(accountId)) {
      issues.add('認可文書に対応する本人が存在しない: $accountId');
    }
  }
  return AccountPermissionsPlan(documents, issues);
}

bool _samePermissions(
  Map<String, Object?> current,
  Map<String, Object?> desired,
) {
  if (current['memberId'] != desired['memberId']) return false;
  for (final key in ['memberGroupIds', 'managedGroupIds']) {
    final actual = current[key];
    final expected = (desired[key]! as List<String>).toSet();
    if (actual is! List ||
        actual.length != expected.length ||
        !actual.toSet().containsAll(expected)) {
      return false;
    }
  }
  return true;
}

List<Map<String, Object?>> accountPermissionsWrites(
  AccountPermissionsPlan plan,
  Map<String, Map<String, Object?>> existing,
  String documentRoot,
) {
  if (plan.issues.isNotEmpty) {
    throw const FormatException('不整合を解消してから認可情報を補完してください');
  }
  return [
    for (final entry in plan.documents.entries)
      if (!existing.containsKey(entry.key))
        {
          'update': {
            'name': '$documentRoot/account_permissions/${entry.key}',
            'fields': entry.value.map(
              (key, value) => MapEntry(key, encode(value)),
            ),
          },
          'currentDocument': {'exists': false},
        },
  ];
}

Future<void> main(List<String> args) async {
  late final ({String projectId, String reportPath, bool apply}) options;
  try {
    options = migrationArguments(args);
  } on FormatException {
    stderr.writeln(
      '使い方: dart run scripts/firebase/backfill_account_permissions.dart <projectId> <report.json> [--apply]',
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
    'appliedAccountIds': <String>[],
  };
  Future<void> saveReport() async {
    await File(options.reportPath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
  }
  Future<Map<String, Map<String, Object?>>> load(String collection) async => {
    for (final doc in await client.queryDocuments(collection))
      (doc['name'] as String).split('/').last: fields(doc),
  };
  try {
    final members = await load('members');
    final groups = await load('groups');
    final memberships = await load('group_members');
    final existing = await load('account_permissions');
    final plan = buildAccountPermissionsPlan(
      members: members,
      groups: groups,
      memberships: memberships,
      existing: existing,
    );
    report['documents'] = plan.documents;
    report['issues'] = plan.issues;
    report['status'] = '確認のみ';
    await saveReport();
    if (plan.issues.isNotEmpty) {
      report['status'] = '不整合あり・適用不可';
      await saveReport();
      stderr.writeln('不整合が${plan.issues.length}件あります。レポートを確認してください');
      exitCode = 1;
      return;
    }
    if (options.apply) {
      final writes = accountPermissionsWrites(plan, existing, client.documentRoot);
      for (var start = 0; start < writes.length; start += 500) {
        final end = start + 500 < writes.length ? start + 500 : writes.length;
        final batch = writes.sublist(start, end);
        report['status'] = '適用中';
        report['pendingAccountIds'] = [
          for (final write in batch)
            ((write['update'] as Map)['name'] as String).split('/').last,
        ];
        await saveReport();
        await client.commit(batch);
        (report['appliedAccountIds']! as List<String>).addAll(
          report['pendingAccountIds']! as List<String>,
        );
        report.remove('pendingAccountIds');
        await saveReport();
      }
      report['status'] = '適用済み';
      await saveReport();
    }
    stdout.writeln('対象=${plan.documents.length}: ${options.reportPath}');
  } catch (error) {
    report['status'] = '失敗または結果不明';
    await saveReport();
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    client.close();
  }
}
