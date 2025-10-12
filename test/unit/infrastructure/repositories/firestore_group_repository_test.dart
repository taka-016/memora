import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_group_repository.dart';
import 'package:memora/domain/entities/group.dart';
import '../../../helpers/test_exception.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
  WriteBatch,
  FirestoreGroupRepository,
])
import 'firestore_group_repository_test.mocks.dart';

void main() {
  group('FirestoreGroupRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreGroupRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc2;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('groups')).thenReturn(mockCollection);
      repository = FirestoreGroupRepository(firestore: mockFirestore);
    });

    test('saveGroupがgroups collectionにグループ情報を追加し、自動採番IDを返す', () async {
      final group = Group(
        id: '',
        ownerId: 'admin001',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockCollection.doc()).thenReturn(mockDocRef);
      when(mockDocRef.id).thenReturn('auto_generated_id');
      when(mockBatch.set(any, any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      final result = await repository.saveGroup(group);

      expect(result, 'auto_generated_id');
      verify(mockFirestore.batch()).called(1);
      verify(mockCollection.doc()).called(1);
      verify(mockBatch.set(mockDocRef, any)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('getGroupsがFirestoreからGroupのリストを返す', () async {
      // groupsコレクションのモック
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({'name': 'テストグループ1', 'memo': 'テストメモ1'});

      when(mockDoc2.id).thenReturn('group002');
      when(mockDoc2.data()).thenReturn({'name': 'テストグループ2', 'memo': 'テストメモ2'});

      final result = await repository.getGroups();

      expect(result.length, 2);
      expect(result[0].id, 'group001');
      expect(result[0].name, 'テストグループ1');
      expect(result[0].memo, 'テストメモ1');
      expect(result[1].id, 'group002');
      expect(result[1].name, 'テストグループ2');
      expect(result[1].memo, 'テストメモ2');
    });

    test('getGroupsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(TestException('Firestore error'));

      final result = await repository.getGroups();

      expect(result, isEmpty);
    });

    test('deleteGroupがgroups collectionの該当ドキュメントを削除する', () async {
      const groupId = 'group001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      // group_membersコレクション用のモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockCollection.doc(groupId)).thenReturn(mockDocRef);

      // group_membersの削除処理
      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([]);

      when(mockBatch.delete(any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteGroup(groupId);

      verify(mockFirestore.batch()).called(1);
      verify(mockBatch.delete(mockDocRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('getGroupByIdが特定のグループを返す', () async {
      const groupId = 'group001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(groupId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(groupId);
      when(
        mockDocSnapshot.data(),
      ).thenReturn({'ownerId': 'owner-id', 'name': 'テストグループ', 'memo': 'テストメモ'});

      // group_membersのモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(mockDoc1.data()).thenReturn({
        'groupId': groupId,
        'memberId': 'member001',
        'isAdministrator': true,
      });

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([mockDoc1]);

      final result = await repository.getGroupById(groupId);

      expect(result, isNotNull);
      expect(result!.id, groupId);
      expect(result.ownerId, 'owner-id');
      expect(result.name, 'テストグループ');
      expect(result.memo, 'テストメモ');
      expect(result.members.length, 1);
      expect(result.members[0].groupId, groupId);
      expect(result.members[0].memberId, 'member001');
      expect(result.members[0].isAdministrator, true);
    });

    test('getGroupByIdが存在しないグループでnullを返す', () async {
      const groupId = 'nonexistent';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(groupId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.getGroupById(groupId);

      expect(result, isNull);
    });

    test('getGroupsByOwnerIdが指定したownerIdのグループ一覧を返す', () async {
      const ownerId = 'admin001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(mockDoc1.id).thenReturn('group001');
      when(
        mockDoc1.data(),
      ).thenReturn({'ownerId': ownerId, 'name': 'テストグループ', 'memo': 'テストメモ'});

      when(mockDoc2.id).thenReturn('group002');
      when(
        mockDoc2.data(),
      ).thenReturn({'ownerId': ownerId, 'name': 'テストグループ2', 'memo': 'テストメモ2'});

      final result = await repository.getGroupsByOwnerId(ownerId);

      expect(result.length, 2);
      expect(result[0].id, 'group001');
      expect(result[0].ownerId, ownerId);
      expect(result[0].name, 'テストグループ');
      expect(result[0].memo, 'テストメモ');
      expect(result[1].id, 'group002');
      expect(result[1].ownerId, ownerId);
      expect(result[1].name, 'テストグループ2');
      expect(result[1].memo, 'テストメモ2');
    });

    test('getGroupsByOwnerIdがエラー時に空のリストを返す', () async {
      const ownerId = 'admin001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenThrow(TestException('Firestore error'));

      final result = await repository.getGroupsByOwnerId(ownerId);

      expect(result, isEmpty);
    });

    test('指定したmemberIdが所有者のグループ一覧を返す', () async {
      const memberId = 'member001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('ownerId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({
        'ownerId': memberId,
        'name': '所有者グループ',
        'memo': '所有者のテストグループ',
      });

      final result = await repository.getGroupsWhereUserIsAdmin(memberId);

      expect(result.length, 1);
      expect(result[0].id, 'group001');
      expect(result[0].ownerId, memberId);
      expect(result[0].name, '所有者グループ');
      expect(result[0].memo, '所有者のテストグループ');

      verify(mockCollection.where('ownerId', isEqualTo: memberId)).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('所有者のグループが存在しない場合、空のリストを返す', () async {
      const memberId = 'member001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockEmptySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('ownerId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockEmptySnapshot);
      when(mockEmptySnapshot.docs).thenReturn([]);

      final result = await repository.getGroupsWhereUserIsAdmin(memberId);

      expect(result, isEmpty);
      verify(mockCollection.where('ownerId', isEqualTo: memberId)).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('複数の所有者グループがある場合、全てのグループを返す', () async {
      const memberId = 'member001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('ownerId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({
        'ownerId': memberId,
        'name': '所有者グループ1',
        'memo': '最初の所有者グループ',
      });

      when(mockDoc2.id).thenReturn('group002');
      when(mockDoc2.data()).thenReturn({
        'ownerId': memberId,
        'name': '所有者グループ2',
        'memo': '2番目の所有者グループ',
      });

      final result = await repository.getGroupsWhereUserIsAdmin(memberId);

      expect(result.length, 2);
      expect(result[0].id, 'group001');
      expect(result[0].name, '所有者グループ1');
      expect(result[1].id, 'group002');
      expect(result[1].name, '所有者グループ2');

      verify(mockCollection.where('ownerId', isEqualTo: memberId)).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('指定したmemberIdがメンバーのグループ一覧を返す', () async {
      const memberId = 'member001';
      const groupId1 = 'group001';
      const groupId2 = 'group002';

      // group_membersコレクションのモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      // groupsコレクションのモック
      final mockGroupDoc1 = MockDocumentReference<Map<String, dynamic>>();
      final mockGroupDoc2 = MockDocumentReference<Map<String, dynamic>>();
      final mockGroupSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.data()).thenReturn({'groupId': groupId1});
      when(mockDoc2.data()).thenReturn({'groupId': groupId2});

      when(mockCollection.doc(groupId1)).thenReturn(mockGroupDoc1);
      when(mockGroupDoc1.get()).thenAnswer((_) async => mockGroupSnapshot1);
      when(mockGroupSnapshot1.exists).thenReturn(true);
      when(mockGroupSnapshot1.id).thenReturn(groupId1);
      when(mockGroupSnapshot1.data()).thenReturn({
        'ownerId': 'other-admin',
        'name': 'メンバーグループ1',
        'memo': 'メンバーのテストグループ1',
      });

      when(mockCollection.doc(groupId2)).thenReturn(mockGroupDoc2);
      when(mockGroupDoc2.get()).thenAnswer((_) async => mockGroupSnapshot2);
      when(mockGroupSnapshot2.exists).thenReturn(true);
      when(mockGroupSnapshot2.id).thenReturn(groupId2);
      when(mockGroupSnapshot2.data()).thenReturn({
        'ownerId': 'other-admin',
        'name': 'メンバーグループ2',
        'memo': 'メンバーのテストグループ2',
      });

      final result = await repository.getGroupsWhereUserIsMember(memberId);

      expect(result.length, 2);
      expect(result[0].id, groupId1);
      expect(result[0].ownerId, 'other-admin');
      expect(result[0].name, 'メンバーグループ1');
      expect(result[0].memo, 'メンバーのテストグループ1');
      expect(result[1].id, groupId2);
      expect(result[1].ownerId, 'other-admin');
      expect(result[1].name, 'メンバーグループ2');
      expect(result[1].memo, 'メンバーのテストグループ2');

      verify(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).called(1);
      verify(mockGroupMembersQuery.get()).called(1);
      verify(mockCollection.doc(groupId1)).called(1);
      verify(mockGroupDoc1.get()).called(1);
      verify(mockCollection.doc(groupId2)).called(1);
      verify(mockGroupDoc2.get()).called(1);
    });

    test('メンバーのグループが存在しない場合、空のリストを返す', () async {
      const memberId = 'member001';

      // group_membersコレクションのモック（空の結果）
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockEmptyGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockEmptyGroupMembersSnapshot);
      when(mockEmptyGroupMembersSnapshot.docs).thenReturn([]);

      final result = await repository.getGroupsWhereUserIsMember(memberId);

      expect(result, isEmpty);
      verify(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).called(1);
      verify(mockGroupMembersQuery.get()).called(1);
    });

    test('複数のメンバーグループがある場合、全てのグループを返す', () async {
      const memberId = 'member001';
      const groupId1 = 'group001';
      const groupId2 = 'group002';

      // group_membersコレクションのモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      // groupsコレクションのモック
      final mockGroupDoc1 = MockDocumentReference<Map<String, dynamic>>();
      final mockGroupDoc2 = MockDocumentReference<Map<String, dynamic>>();
      final mockGroupSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.data()).thenReturn({'groupId': groupId1});
      when(mockDoc2.data()).thenReturn({'groupId': groupId2});

      // 1つ目のグループ
      when(mockCollection.doc(groupId1)).thenReturn(mockGroupDoc1);
      when(mockGroupDoc1.get()).thenAnswer((_) async => mockGroupSnapshot1);
      when(mockGroupSnapshot1.exists).thenReturn(true);
      when(mockGroupSnapshot1.id).thenReturn(groupId1);
      when(mockGroupSnapshot1.data()).thenReturn({
        'ownerId': 'admin001',
        'name': 'メンバーグループ1',
        'memo': '1つ目のメンバーグループ',
      });

      // 2つ目のグループ
      when(mockCollection.doc(groupId2)).thenReturn(mockGroupDoc2);
      when(mockGroupDoc2.get()).thenAnswer((_) async => mockGroupSnapshot2);
      when(mockGroupSnapshot2.exists).thenReturn(true);
      when(mockGroupSnapshot2.id).thenReturn(groupId2);
      when(mockGroupSnapshot2.data()).thenReturn({
        'ownerId': 'admin002',
        'name': 'メンバーグループ2',
        'memo': '2つ目のメンバーグループ',
      });

      final result = await repository.getGroupsWhereUserIsMember(memberId);

      expect(result.length, 2);
      expect(result[0].id, groupId1);
      expect(result[0].name, 'メンバーグループ1');
      expect(result[1].id, groupId2);
      expect(result[1].name, 'メンバーグループ2');

      verify(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).called(1);
      verify(mockGroupMembersQuery.get()).called(1);
      verify(mockCollection.doc(groupId1)).called(1);
      verify(mockCollection.doc(groupId2)).called(1);
    });

    test('グループが存在しないgroup_memberレコードがある場合、そのグループは結果に含まれない', () async {
      const memberId = 'member001';
      const existingGroupId = 'group001';
      const nonExistingGroupId = 'group002';

      // group_membersコレクションのモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      // groupsコレクションのモック
      final mockExistingGroupDoc =
          MockDocumentReference<Map<String, dynamic>>();
      final mockNonExistingGroupDoc =
          MockDocumentReference<Map<String, dynamic>>();
      final mockExistingGroupSnapshot =
          MockDocumentSnapshot<Map<String, dynamic>>();
      final mockNonExistingGroupSnapshot =
          MockDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.data()).thenReturn({'groupId': existingGroupId});
      when(mockDoc2.data()).thenReturn({'groupId': nonExistingGroupId});

      // 存在するグループ
      when(
        mockCollection.doc(existingGroupId),
      ).thenReturn(mockExistingGroupDoc);
      when(
        mockExistingGroupDoc.get(),
      ).thenAnswer((_) async => mockExistingGroupSnapshot);
      when(mockExistingGroupSnapshot.exists).thenReturn(true);
      when(mockExistingGroupSnapshot.id).thenReturn(existingGroupId);
      when(mockExistingGroupSnapshot.data()).thenReturn({
        'ownerId': 'admin001',
        'name': '存在するグループ',
        'memo': '存在するメンバーグループ',
      });

      // 存在しないグループ
      when(
        mockCollection.doc(nonExistingGroupId),
      ).thenReturn(mockNonExistingGroupDoc);
      when(
        mockNonExistingGroupDoc.get(),
      ).thenAnswer((_) async => mockNonExistingGroupSnapshot);
      when(mockNonExistingGroupSnapshot.exists).thenReturn(false);

      final result = await repository.getGroupsWhereUserIsMember(memberId);

      expect(result.length, 1);
      expect(result[0].id, existingGroupId);
      expect(result[0].name, '存在するグループ');

      verify(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).called(1);
      verify(mockGroupMembersQuery.get()).called(1);
      verify(mockCollection.doc(existingGroupId)).called(1);
      verify(mockCollection.doc(nonExistingGroupId)).called(1);
    });
  });
}
