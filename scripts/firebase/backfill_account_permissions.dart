import 'dart:convert';
import 'dart:io';

import '../timetree/import_timetree.dart' show FirestoreImportClient;
import 'migrate_firestore_read_models.dart'
    show encode, fields, migrationArguments, tripChildrenGroupMigrationWrites;

class AccountPermissionsPlan {
  const AccountPermissionsPlan(
    this.documents,
    this.issues, {
    this.memberDocuments = const {},
  });

  final Map<String, Map<String, Object?>> memberDocuments;

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
  final profiles = <String, Map<String, Object?>>{};
  for (final entry in members.entries) {
    final account = existing[entry.value['accountId']];
    final groups = (memberGroups[entry.key] ?? {}).toList()..sort();
    final managed = (managedGroups[entry.key] ?? {}).toList()..sort();
    final expected = {
      'memberId': entry.key,
      'memberGroupIds': groups,
      'managedGroupIds': managed,
    };
    final useExisting = account != null && _samePermissions(account, expected);
    profiles[entry.key] = {
      'groupIds': useExisting ? account['memberGroupIds'] : groups,
      'managedGroupIds': useExisting ? account['managedGroupIds'] : managed,
    };
    final data = entry.value;
    if (data.containsKey('groupIds') || data.containsKey('managedGroupIds')) {
      if (!_samePermissions({
        'memberId': entry.key,
        'memberGroupIds': data['groupIds'],
        'managedGroupIds': data['managedGroupIds'],
      }, expected)) {
        issues.add('メンバーの所属一覧と不一致: ${entry.key}');
      }
    }
  }
  for (final id in [...groups.keys, ...members.keys]) {
    if (id.contains(':')) issues.add('所属参照IDの区切り文字を含むID: $id');
  }
  return AccountPermissionsPlan(documents, issues, memberDocuments: profiles);
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

List<List<Map<String, Object?>>> authorizationStorageWrites(
  AccountPermissionsPlan plan,
  Map<String, List<Map<String, dynamic>>> collections,
) {
  if (plan.issues.isNotEmpty) throw const FormatException('不整合を解消してから補完してください');
  final units = <List<Map<String, Object?>>>[];
  for (final doc in collections['members'] ?? <Map<String, dynamic>>[]) {
    final name = doc['name'] as String;
    final id = name.split('/').last;
    final desired = plan.memberDocuments[id]!;
    final data = fields(doc);
    if (jsonEncode(data['groupIds']) == jsonEncode(desired['groupIds']) &&
        jsonEncode(data['managedGroupIds']) ==
            jsonEncode(desired['managedGroupIds'])) {
      continue;
    }
    final version = data['version'];
    if (version is! int || version < 1) {
      throw FormatException('メンバーのバージョンを確認してください: $id');
    }
    units.add([
      {
        'update': {
          'name': name,
          'fields': {
            ...desired.map((key, value) => MapEntry(key, encode(value))),
            'version': encode(version + 1),
          },
        },
        'updateMask': {
          'fieldPaths': ['groupIds', 'managedGroupIds', 'version'],
        },
        'currentDocument': {'updateTime': doc['updateTime']},
      },
    ]);
  }
  final invitationCodes = <String>{};
  for (final collection in ['group_members', 'member_invitations']) {
    for (final doc in collections[collection] ?? <Map<String, dynamic>>[]) {
      final name = doc['name'] as String;
      final data = fields(doc);
      late final String id;
      if (collection == 'group_members') {
        final member = plan.memberDocuments[data['memberId']];
        if (member == null ||
            !(member['groupIds']! as List).contains(data['groupId'])) {
          continue;
        }
        id = '${data['groupId']}:${data['memberId']}';
      } else {
        id = data['invitationCode'] as String;
        if (id.isEmpty || id.contains('/') || !invitationCodes.add(id)) {
          throw const FormatException('招待コードの重複または形式を確認してください');
        }
      }
      final target = '${name.substring(0, name.lastIndexOf('/'))}/$id';
      if (target == name) continue;
      units.add([
        {
          'update': {'name': target, 'fields': doc['fields']},
          'currentDocument': {'exists': false},
        },
        {
          'delete': name,
          'currentDocument': {'updateTime': doc['updateTime']},
        },
      ]);
    }
  }
  for (final parent
      in collections['trip_entries'] ?? <Map<String, dynamic>>[]) {
    final id = (parent['name'] as String).split('/').last;
    final children = (collections['tasks'] ?? <Map<String, dynamic>>[])
        .where((doc) => fields(doc)['tripId'] == id)
        .toList();
    if (children.isEmpty) continue;
    final data = fields(parent);
    final groupId = data['groupId'];
    if (groupId is! String || groupId.isEmpty) {
      throw FormatException('旅行の保存先を確認してください: $id');
    }
    for (final child in children) {
      final scope = fields(child)['groupId'];
      if (scope != null && scope != groupId) {
        throw FormatException('タスクと親旅行の保存先が不一致です: ${child['name']}');
      }
    }
    if (children.every((doc) => fields(doc)['groupId'] == groupId)) continue;
    final version = data['version'];
    if (version is! int || version < 1) {
      throw FormatException('旅行のバージョンを確認してください: $id');
    }
    units.add(tripChildrenGroupMigrationWrites(parent, children));
  }
  return units;
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
    'appliedDocuments': <String>[],
  };
  Future<void> saveReport() async {
    await File(options.reportPath)
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  }

  final sources = <String, List<Map<String, dynamic>>>{};
  Future<Map<String, Map<String, Object?>>> load(String collection) async {
    final docs = await client.queryDocuments(collection);
    sources[collection] = docs;
    return {
      for (final doc in docs)
        (doc['name'] as String).split('/').last: fields(doc),
    };
  }

  try {
    final members = await load('members');
    final groups = await load('groups');
    final memberships = await load('group_members');
    final existing = await load('account_permissions');
    await load('member_invitations');
    await load('trip_entries');
    await load('tasks');
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
    final units = [
      for (final write in accountPermissionsWrites(
        plan,
        existing,
        client.documentRoot,
      ))
        [write],
      ...authorizationStorageWrites(plan, sources),
    ];
    report['memberDocuments'] = plan.memberDocuments;
    report['writeUnits'] = units.length;
    final tripIds = {
      for (final parent in sources['trip_entries']!)
        (parent['name'] as String).split('/').last,
    };
    report['retainedTaskIds'] = [
      for (final task in sources['tasks']!)
        if (!tripIds.contains(fields(task)['tripId']))
          (task['name'] as String).split('/').last,
    ];
    await saveReport();
    if (options.apply) {
      for (final unit in units) {
        final paths = [
          for (final write in unit)
            (write['update'] as Map?)?['name'] ?? write['delete'],
        ];
        report['status'] = '適用中';
        report['pendingDocuments'] = paths;
        await saveReport();
        await client.commit(unit);
        (report['appliedDocuments']! as List<String>).addAll(
          paths.cast<String>(),
        );
        report.remove('pendingDocuments');
        await saveReport();
      }
      report['status'] = '適用済み';
      await saveReport();
    }
    stdout.writeln('対象=${plan.documents.length}: ${options.reportPath}');
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
