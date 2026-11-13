import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/services/firestore_account_permissions_source.dart';

import '../../../../helpers/firestore_transaction_store.dart';
import '../../../../helpers/test_exception.dart';
import 'firestore_group_repository_test.mocks.dart';

@GenerateMocks([FirestoreAccountPermissionsSource, FirestoreGroupRepository])
void main() {
  late FirestoreTransactionStore store;
  late FirestoreGroupRepository repo;
  late MockFirestoreAccountPermissionsSource permissions;
  setUp(() {
    store = FirestoreTransactionStore();
    permissions = MockFirestoreAccountPermissionsSource();
    when(permissions.current()).thenAnswer((_) async => FirestoreAccountPermissions({
      'memberId': 'self', 'memberGroupIds': <String>[], 'managedGroupIds': <String>[],
    }));
    repo = FirestoreGroupRepository(firestore: store.firestore, permissions: permissions);
    store.rows['members/self'] = {'version': 1, 'accountId': 'uid', 'groupIds': <String>[], 'managedGroupIds': <String>[]};
    store.rows['account_permissions/uid'] = {'memberId': 'self', 'memberGroupIds': <String>[], 'managedGroupIds': <String>[]};
  });

  test('作成者を本人の認可から所有者かつ所属者にして同時保存する', () async {
    final id = await repo.saveGroup(Group(id: '', ownerId: '偽の所有者', name: '家族'));
    expect(store.rows['groups/$id']!['ownerId'], 'self');
    expect(store.rows['group_members/$id:self']!['memberId'], 'self');
    expect(store.rows['members/self']!['groupIds'], [id]);
    expect(store.rows['account_permissions/uid']!['managedGroupIds'], [id]);
    expect(store.commits, 1);
  });

  test('所属追加・管理者変更とプロフィールの所属一覧と認可を同時に保存する', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'self'};
    const self = GroupMember(groupId: 'g', memberId: 'self');
    const added = GroupMember(groupId: 'g', memberId: 'other', isAdministrator: true);
    store.rows['members/other'] = {'version': 4, 'accountId': 'otherUid', 'groupIds': ['else'], 'managedGroupIds': <String>[]};
    store.rows['account_permissions/otherUid'] = {'memberId': 'other', 'memberGroupIds': ['else'], 'managedGroupIds': <String>[]};
    await repo.updateGroup(Group(id: 'g', ownerId: 'self', name: '家族', version: 3, originalMembers: const [self], members: const [self, added]));
    expect(store.rows['groups/g']!['version'], 4);
    expect(store.rows['group_members/g:other']!['isAdministrator'], true);
    expect(store.rows['members/other']!['groupIds'], ['else', 'g']);
    expect(store.rows['members/other']!['version'], 5);
    expect(store.rows['account_permissions/otherUid']!['managedGroupIds'], ['g']);
    expect(store.commits, 1);
  });

  test('所属色だけの変更ではプロフィールと認可を更新しない', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'self'};
    const before = GroupMember(groupId: 'g', memberId: 'self');
    await repo.updateGroup(Group(id: 'g', ownerId: 'self', name: '家族', version: 3, originalMembers: const [before], members: [before.copyWith(color: '#FF0000')]));
    expect(store.rows['group_members/g:self']!['color'], '#FF0000');
    expect(store.rows['members/self']!['version'], 1);
  });

  test('競合と保存拒否では所属と認可を一部だけ変更しない', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'self'};
    store.commitError = TestException();
    const self = GroupMember(groupId: 'g', memberId: 'self');
    await expectLater(repo.updateGroup(Group(id: 'g', ownerId: 'self', name: '家族', version: 3, originalMembers: const [], members: const [self])), throwsA(isA<TestException>()));
    expect(store.rows['groups/g']!['version'], 3);
    expect(store.rows.containsKey('group_members/g:self'), false);
    expect(store.rows['members/self']!['version'], 1);
    store.commitError = null;
    await expectLater(repo.updateGroup(Group(id: 'g', ownerId: 'self', name: '家族', version: 2, members: const [self])), throwsA(isA<FirebaseException>()));
    expect(store.commits, 0);
  });
}
