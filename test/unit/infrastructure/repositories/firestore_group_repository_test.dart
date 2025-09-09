import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_group_repository.dart';
import 'package:memora/domain/entities/group.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentSnapshot,
  Query,
  FirestoreGroupRepository,
])
import 'firestore_group_repository_test.mocks.dart';

// テスト用のFirestoreGroupRepositoryの拡張
class _TestFirestoreGroupRepository extends FirestoreGroupRepository {
  final MockFirestoreGroupRepository mockRepository;

  _TestFirestoreGroupRepository({
    required super.firestore,
    required this.mockRepository,
  });

  @override
  Future<List<Group>> getGroupsByAdministratorId(String administratorId) {
    return mockRepository.getGroupsByAdministratorId(administratorId);
  }

  @override
  Future<List<Group>> getGroupsWhereUserIsAdmin(String memberId) {
    return mockRepository.getGroupsWhereUserIsAdmin(memberId);
  }

  @override
  Future<List<Group>> getGroupsWhereUserIsMember(String memberId) {
    return mockRepository.getGroupsWhereUserIsMember(memberId);
  }
}

void main() {
  group('FirestoreGroupRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreGroupRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('groups')).thenReturn(mockCollection);
      repository = FirestoreGroupRepository(firestore: mockFirestore);
    });

    void setupMembersForGroupMocks(String memberId, List<Group> allGroups) {
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMembersDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockMemberDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      for (final group in allGroups) {
        when(
          mockGroupMembersCollection.where('groupId', isEqualTo: group.id),
        ).thenReturn(mockGroupMembersQuery);
        when(
          mockGroupMembersQuery.get(),
        ).thenAnswer((_) async => mockGroupMembersSnapshot);
        when(mockGroupMembersSnapshot.docs).thenReturn([mockGroupMembersDoc]);
        when(mockGroupMembersDoc.data()).thenReturn({'memberId': memberId});
        when(mockMembersCollection.doc(memberId)).thenReturn(mockMemberDoc);
        when(mockMemberDoc.get()).thenAnswer((_) async => mockMemberSnapshot);
        when(mockMemberSnapshot.exists).thenReturn(true);
        when(mockMemberSnapshot.id).thenReturn(memberId);
        when(
          mockMemberSnapshot.data(),
        ).thenReturn({'displayName': 'テストユーザー', 'email': 'test@example.com'});
      }
    }

    test('saveGroupがgroups collectionにグループ情報を追加し、自動採番IDを返す', () async {
      final group = Group(
        id: '',
        administratorId: 'admin001',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);
      when(mockDocRef.id).thenReturn('auto_generated_id');

      final result = await repository.saveGroup(group);

      expect(result, 'auto_generated_id');
      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('name', 'テストグループ'),
              containsPair('memo', 'テストメモ'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('getGroupsがFirestoreからGroupのリストを返す', () async {
      // groupsコレクションのモック
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({'name': 'テストグループ', 'memo': 'テストメモ'});

      // group_membersコレクションのモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group001'),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(mockGroupMemberDoc.id).thenReturn('group_member001');
      when(
        mockGroupMemberDoc.data(),
      ).thenReturn({'groupId': 'group001', 'memberId': 'member001'});

      // group_eventsコレクションのモック
      final mockGroupEventsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupEventsQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupEventsSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupEventDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_events'),
      ).thenReturn(mockGroupEventsCollection);
      when(
        mockGroupEventsCollection.where('groupId', isEqualTo: 'group001'),
      ).thenReturn(mockGroupEventsQuery);
      when(
        mockGroupEventsQuery.get(),
      ).thenAnswer((_) async => mockGroupEventsSnapshot);
      when(mockGroupEventsSnapshot.docs).thenReturn([mockGroupEventDoc]);
      when(mockGroupEventDoc.id).thenReturn('group_event001');
      when(mockGroupEventDoc.data()).thenReturn({
        'groupId': 'group001',
        'type': 'meeting',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final result = await repository.getGroups();

      expect(result.length, 1);
      expect(result[0].id, 'group001');
      expect(result[0].name, 'テストグループ');
      expect(result[0].memo, 'テストメモ');
      expect(result[0].members?.length, 1);
      expect(result[0].members?[0].id, 'group_member001');
      expect(result[0].members?[0].memberId, 'member001');
      expect(result[0].events?.length, 1);
      expect(result[0].events?[0].id, 'group_event001');
      expect(result[0].events?[0].name, 'テストイベント');
    });

    test('getGroupsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getGroups();

      expect(result, isEmpty);
    });

    test('deleteGroupがgroups collectionの該当ドキュメントを削除する', () async {
      const groupId = 'group001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(groupId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteGroup(groupId);

      verify(mockCollection.doc(groupId)).called(1);
      verify(mockDocRef.delete()).called(1);
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
      ).thenReturn({'name': 'テストグループ', 'memo': 'テストメモ'});

      final result = await repository.getGroupById(groupId);

      expect(result, isNotNull);
      expect(result!.id, groupId);
      expect(result.name, 'テストグループ');
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

    test('getGroupsByAdministratorIdが指定したadministratorIdのグループ一覧を返す', () async {
      const administratorId = 'admin001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('administratorId', isEqualTo: administratorId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({
        'administratorId': administratorId,
        'name': 'テストグループ',
        'memo': 'テストメモ',
      });

      final result = await repository.getGroupsByAdministratorId(
        administratorId,
      );

      expect(result.length, 1);
      expect(result[0].id, 'group001');
      expect(result[0].administratorId, administratorId);
      expect(result[0].name, 'テストグループ');
      expect(result[0].memo, 'テストメモ');
    });

    test('getGroupsByAdministratorIdがエラー時に空のリストを返す', () async {
      const administratorId = 'admin001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('administratorId', isEqualTo: administratorId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getGroupsByAdministratorId(
        administratorId,
      );

      expect(result, isEmpty);
    });

    test('指定したmemberIdが管理者のグループ一覧を返す', () async {
      const memberId = 'member001';
      final mockQuery = MockQuery<Map<String, dynamic>>();

      when(
        mockCollection.where('administratorId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({
        'administratorId': memberId,
        'name': '管理者グループ',
        'memo': '管理者のテストグループ',
      });

      final result = await repository.getGroupsWhereUserIsAdmin(memberId);

      expect(result.length, 1);
      expect(result[0].id, 'group001');
      expect(result[0].administratorId, memberId);
      expect(result[0].name, '管理者グループ');
      expect(result[0].memo, '管理者のテストグループ');

      verify(
        mockCollection.where('administratorId', isEqualTo: memberId),
      ).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('管理者のグループが存在しない場合、空のリストを返す', () async {
      const memberId = 'member001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockEmptySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('administratorId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockEmptySnapshot);
      when(mockEmptySnapshot.docs).thenReturn([]);

      final result = await repository.getGroupsWhereUserIsAdmin(memberId);

      expect(result, isEmpty);
      verify(
        mockCollection.where('administratorId', isEqualTo: memberId),
      ).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('複数の管理者グループがある場合、全てのグループを返す', () async {
      const memberId = 'member001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('administratorId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);

      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({
        'administratorId': memberId,
        'name': '管理者グループ1',
        'memo': '最初の管理者グループ',
      });

      when(mockDoc2.id).thenReturn('group002');
      when(mockDoc2.data()).thenReturn({
        'administratorId': memberId,
        'name': '管理者グループ2',
        'memo': '2番目の管理者グループ',
      });

      final result = await repository.getGroupsWhereUserIsAdmin(memberId);

      expect(result.length, 2);
      expect(result[0].id, 'group001');
      expect(result[0].name, '管理者グループ1');
      expect(result[1].id, 'group002');
      expect(result[1].name, '管理者グループ2');

      verify(
        mockCollection.where('administratorId', isEqualTo: memberId),
      ).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('指定したmemberIdがメンバーのグループ一覧を返す', () async {
      const memberId = 'member001';
      const groupId = 'group001';

      // group_membersコレクションのモック
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      // groupsコレクションのモック
      final mockGroupDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockGroupSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMembersQuery);
      when(
        mockGroupMembersQuery.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(mockGroupMemberDoc.data()).thenReturn({'groupId': groupId});

      when(mockCollection.doc(groupId)).thenReturn(mockGroupDoc);
      when(mockGroupDoc.get()).thenAnswer((_) async => mockGroupSnapshot);
      when(mockGroupSnapshot.exists).thenReturn(true);
      when(mockGroupSnapshot.id).thenReturn(groupId);
      when(mockGroupSnapshot.data()).thenReturn({
        'administratorId': 'other-admin',
        'name': 'メンバーグループ',
        'memo': 'メンバーのテストグループ',
      });

      final result = await repository.getGroupsWhereUserIsMember(memberId);

      expect(result.length, 1);
      expect(result[0].id, groupId);
      expect(result[0].administratorId, 'other-admin');
      expect(result[0].name, 'メンバーグループ');
      expect(result[0].memo, 'メンバーのテストグループ');

      verify(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).called(1);
      verify(mockGroupMembersQuery.get()).called(1);
      verify(mockCollection.doc(groupId)).called(1);
      verify(mockGroupDoc.get()).called(1);
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
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

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
      when(
        mockGroupMembersSnapshot.docs,
      ).thenReturn([mockGroupMemberDoc1, mockGroupMemberDoc2]);
      when(mockGroupMemberDoc1.data()).thenReturn({'groupId': groupId1});
      when(mockGroupMemberDoc2.data()).thenReturn({'groupId': groupId2});

      // 1つ目のグループ
      when(mockCollection.doc(groupId1)).thenReturn(mockGroupDoc1);
      when(mockGroupDoc1.get()).thenAnswer((_) async => mockGroupSnapshot1);
      when(mockGroupSnapshot1.exists).thenReturn(true);
      when(mockGroupSnapshot1.id).thenReturn(groupId1);
      when(mockGroupSnapshot1.data()).thenReturn({
        'administratorId': 'admin001',
        'name': 'メンバーグループ1',
        'memo': '1つ目のメンバーグループ',
      });

      // 2つ目のグループ
      when(mockCollection.doc(groupId2)).thenReturn(mockGroupDoc2);
      when(mockGroupDoc2.get()).thenAnswer((_) async => mockGroupSnapshot2);
      when(mockGroupSnapshot2.exists).thenReturn(true);
      when(mockGroupSnapshot2.id).thenReturn(groupId2);
      when(mockGroupSnapshot2.data()).thenReturn({
        'administratorId': 'admin002',
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
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

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
      when(
        mockGroupMembersSnapshot.docs,
      ).thenReturn([mockGroupMemberDoc1, mockGroupMemberDoc2]);
      when(mockGroupMemberDoc1.data()).thenReturn({'groupId': existingGroupId});
      when(
        mockGroupMemberDoc2.data(),
      ).thenReturn({'groupId': nonExistingGroupId});

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
        'administratorId': 'admin001',
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
