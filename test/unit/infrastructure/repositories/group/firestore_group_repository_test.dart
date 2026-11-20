import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/group/group.dart';
import 'package:memora/domain/entities/group/group_member.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/infrastructure/services/firestore_account_member_source.dart';

import '../../../../helpers/firestore_transaction_store.dart';
import '../../../../helpers/test_exception.dart';
import 'firestore_group_repository_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
  WriteBatch,
  FirestoreAccountMemberSource,
  FirestoreGroupRepository,
])
void main() {
  late FirestoreTransactionStore store;
  late FirestoreGroupRepository repo;
  late MockFirestoreAccountMemberSource accountMember;
  setUp(() {
    store = FirestoreTransactionStore();
    accountMember = MockFirestoreAccountMemberSource();
    final self = MockQueryDocumentSnapshot<Map<String, dynamic>>();
    when(self.id).thenReturn('self');
    when(accountMember.current()).thenAnswer((_) async => self);
    repo = FirestoreGroupRepository(
      firestore: store.firestore,
      accountMember: accountMember,
    );
    store.rows['members/self'] = {
      'version': 1,
      'accountId': 'uid',
      'groupIds': <String>[],
      'managedGroupIds': <String>[],
    };
    store.rows['account_permissions/uid'] = {
      'memberId': 'self',
      'memberGroupIds': <String>[],
      'managedGroupIds': <String>[],
    };
  });

  test('グループと作成者の所属を保存しメンバー文書を変更しない', () async {
    final id = await repo.saveGroup(
      Group(id: '', ownerId: '偽の所有者', name: '家族'),
    );
    expect(store.rows['groups/$id']!['ownerId'], 'self');
    expect(store.rows['group_members/$id:self']!['memberId'], 'self');
    expect(store.rows['members/self']!['version'], 1);
    expect(store.rows['members/self']!['groupIds'], isEmpty);
    expect(store.commits, 1);
  });

  test('所属を追加してもメンバー文書は変更しない', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'self'};
    const self = GroupMember(groupId: 'g', memberId: 'self');
    const added = GroupMember(
      groupId: 'g',
      memberId: 'other',
      isAdministrator: true,
    );
    store.rows['members/other'] = {
      'version': 4,
      'accountId': 'otherUid',
      'groupIds': ['else'],
      'managedGroupIds': <String>[],
    };
    store.rows['account_permissions/otherUid'] = {
      'memberId': 'other',
      'memberGroupIds': ['else'],
      'managedGroupIds': <String>[],
    };
    await repo.updateGroup(
      Group(
        id: 'g',
        ownerId: 'self',
        name: '家族',
        version: 3,
        originalMembers: const [self],
        members: const [self, added],
      ),
    );
    expect(store.rows['groups/g']!['version'], 4);
    expect(store.rows['group_members/g:other']!['isAdministrator'], true);
    expect(store.rows['members/other']!['groupIds'], ['else']);
    expect(store.rows['members/other']!['version'], 4);
    expect(
      store.rows['account_permissions/otherUid']!['managedGroupIds'],
      isEmpty,
    );
    expect(store.commits, 1);
  });

  test('所属色だけの変更ではメンバー文書を更新しない', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'self'};
    const before = GroupMember(groupId: 'g', memberId: 'self');
    await repo.updateGroup(
      Group(
        id: 'g',
        ownerId: 'self',
        name: '家族',
        version: 3,
        originalMembers: const [before],
        members: [before.copyWith(color: '#FF0000')],
      ),
    );
    expect(store.rows['group_members/g:self']!['color'], '#FF0000');
    expect(store.rows['members/self']!['version'], 1);
  });

  test('競合と保存拒否ではグループと所属を一部だけ変更しない', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'self'};
    store.commitError = TestException();
    const self = GroupMember(groupId: 'g', memberId: 'self');
    await expectLater(
      repo.updateGroup(
        Group(
          id: 'g',
          ownerId: 'self',
          name: '家族',
          version: 3,
          originalMembers: const [],
          members: const [self],
        ),
      ),
      throwsA(isA<TestException>()),
    );
    expect(store.rows['groups/g']!['version'], 3);
    expect(store.rows.containsKey('group_members/g:self'), false);
    expect(store.rows['members/self']!['version'], 1);
    store.commitError = null;
    await expectLater(
      repo.updateGroup(
        Group(
          id: 'g',
          ownerId: 'self',
          name: '家族',
          version: 2,
          members: const [self],
        ),
      ),
      throwsA(isA<FirebaseException>()),
    );
    expect(store.commits, 0);
  });
  test('所有者が削除済みでも既存の管理者はグループ情報を更新できる', () async {
    store.rows['groups/g'] = {'version': 3, 'ownerId': 'deleted'};
    const admin = GroupMember(
      groupId: 'g',
      memberId: 'self',
      isAdministrator: true,
    );
    await repo.updateGroup(
      Group(
        id: 'g',
        ownerId: 'deleted',
        name: '家族',
        version: 3,
        originalMembers: const [admin],
        members: const [admin],
      ),
    );
    expect(store.rows['groups/g']!['version'], 4);
  });

  test('グループ退避では所属を取得し直さずに関連データを保持する', () async {
    final id = await repo.saveGroup(Group(id: '', ownerId: 'self', name: '家族'));
    await repo.deleteGroup(id, expectedVersion: 1);
    expect(store.querySources, isEmpty);
    expect(store.rows.containsKey('groups/$id'), false);
    expect(store.rows['deleted_groups/$id']!['name'], '家族');
    expect(store.rows.containsKey('group_members/$id:self'), true);
    expect(store.rows['members/self']!['groupIds'], isEmpty);
    expect(store.rows['account_permissions/uid']!['memberGroupIds'], isEmpty);
  });
}
