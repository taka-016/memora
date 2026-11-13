import 'migrate_firestore_read_models.dart' show encode;

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
