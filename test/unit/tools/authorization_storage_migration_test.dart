import 'package:flutter_test/flutter_test.dart';
import '../../../scripts/firebase/backfill_account_permissions.dart';

void main() {
  test('所属一覧の補完は未連携メンバーも含み削除済み親を除外する', () {
    final plan = buildAccountPermissionsPlan(
      members: {'m': {'accountId': null}},
      groups: {'g': {'ownerId': 'm'}},
      memberships: {
        'old': {'groupId': 'g', 'memberId': 'm', 'isAdministrator': false},
        'retained': {'groupId': 'gone', 'memberId': 'm'},
      }, existing: {},
    );
    expect(plan.memberDocuments['m'], {'groupIds': ['g'], 'managedGroupIds': ['g']});
  });

  test('メンバーのバージョンを進め所属と招待を直接照合できるIDへ退避なしで移す', () {
    const root = 'projects/p/databases/(default)/documents';
    final plan = buildAccountPermissionsPlan(
      members: {'m': {'accountId': null}},
      groups: {'g': {'ownerId': 'm'}},
      memberships: {'old': {'groupId': 'g', 'memberId': 'm'}}, existing: {},
    );
    final units = authorizationStorageWrites(plan, {
      'members': [
        {'name': '$root/members/m', 'updateTime': 't1', 'fields': {'version': {'integerValue': '2'}}},
      ],
      'group_members': [
        {'name': '$root/group_members/old', 'updateTime': 't2', 'fields': {'groupId': {'stringValue': 'g'}, 'memberId': {'stringValue': 'm'}}},
      ],
      'member_invitations': [
        {'name': '$root/member_invitations/oldInvite', 'updateTime': 't3', 'fields': {'invitationCode': {'stringValue': 'secret'}}},
      ],
    });
    expect(units.length, 3);
    expect(((units[0].single['update'] as Map)['fields'] as Map)['version'], {'integerValue': '3'});
    expect(units[0].single['currentDocument'], {'updateTime': 't1'});
    expect((units[1][0]['update'] as Map)['name'], '$root/group_members/g:m');
    expect(units[1][1]['delete'], '$root/group_members/old');
    expect((units[2][0]['update'] as Map)['name'], '$root/member_invitations/secret');
    expect(units[2][1]['delete'], '$root/member_invitations/oldInvite');
    expect(units[1][0]['currentDocument'], {'exists': false});
  });

  test('補完済み文書は再更新せず所属一覧の不一致は報告する', () {
    final plan = buildAccountPermissionsPlan(
      members: {'m': {'accountId': null, 'groupIds': ['other'], 'managedGroupIds': <String>[]}},
      groups: {}, memberships: {}, existing: {},
    );
    expect(plan.issues, contains(contains('メンバーの所属一覧と不一致')));
  });
}
