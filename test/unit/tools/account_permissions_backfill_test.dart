import 'package:flutter_test/flutter_test.dart';

import '../../../scripts/firebase/backfill_account_permissions.dart';

void main() {
  test('本人・所属・所有者と管理者の役割から認可文書を生成する', () {
    final plan = buildAccountPermissionsPlan(
      members: {
        'm1': {'accountId': 'u1'},
        'm2': {'accountId': 'u2'},
        'unlinked': {'accountId': null},
      },
      groups: {
        'g1': {'ownerId': 'm1'},
        'g2': {'ownerId': 'm2'},
      },
      memberships: {
        'a': {'groupId': 'g1', 'memberId': 'm1', 'isAdministrator': false},
        'b': {'groupId': 'g1', 'memberId': 'm2', 'isAdministrator': true},
        'c': {'groupId': 'g2', 'memberId': 'm2', 'isAdministrator': false},
        'd': {'groupId': 'g2', 'memberId': 'm1', 'isAdministrator': false},
        'e': {'groupId': 'g1', 'memberId': 'unlinked'},
        '残存所属': {'groupId': 'deleted', 'memberId': 'm1'},
        '残存メンバー': {'groupId': 'g1', 'memberId': 'deleted'},
      },
      existing: const {},
    );
    expect(plan.issues, isEmpty);
    expect(plan.documents, {
      'u1': {
        'memberId': 'm1',
        'memberGroupIds': ['g1', 'g2'],
        'managedGroupIds': ['g1'],
      },
      'u2': {
        'memberId': 'm2',
        'memberGroupIds': ['g1', 'g2'],
        'managedGroupIds': ['g1', 'g2'],
      },
    });
  });

  test('同じアカウントの重複対応は補完せず報告する', () {
    final plan = buildAccountPermissionsPlan(
      members: {
        'm1': {'accountId': 'u'},
        'm2': {'accountId': 'u'},
      },
      groups: const {},
      memberships: const {},
      existing: const {},
    );
    expect(plan.issues, contains(contains('重複')));
    expect(plan.documents, isEmpty);
  });

  test('所有者の所属不足・重複所属・既存認可との不一致を報告する', () {
    final plan = buildAccountPermissionsPlan(
      members: {
        'm': {'accountId': 'u'},
      },
      groups: {
        'g1': {'ownerId': 'm'},
        'g2': {'ownerId': 'm'},
      },
      memberships: {
        'a': {'groupId': 'g2', 'memberId': 'm'},
        'b': {'groupId': 'g2', 'memberId': 'm'},
      },
      existing: {
        'u': {
          'memberId': 'other',
          'memberGroupIds': <String>[],
          'managedGroupIds': <String>[],
        },
      },
    );
    expect(plan.issues, contains(contains('所有者')));
    expect(plan.issues, contains(contains('重複所属')));
    expect(plan.issues, contains(contains('不一致')));
  });

  test('所属なしの本人は空の権限を持ち既存の配列順序の違いは不一致にしない', () {
    final plan = buildAccountPermissionsPlan(
      members: {
        'm': {'accountId': 'u'},
      },
      groups: const {},
      memberships: const {},
      existing: {
        'u': {
          'memberId': 'm',
          'memberGroupIds': <String>[],
          'managedGroupIds': <String>[],
        },
        'stale': {
          'memberId': 'deleted',
          'memberGroupIds': ['g'],
          'managedGroupIds': ['g'],
        },
      },
    );
    expect(plan.documents['u'], {
      'memberId': 'm',
      'memberGroupIds': <String>[],
      'managedGroupIds': <String>[],
    });
    expect(plan.issues, contains(contains('対応する本人が存在しない')));
  });
}
