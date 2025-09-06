import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_group_repository.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/group_with_members.dart';
import 'package:memora/domain/entities/member.dart';

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

  @override
  Future<List<GroupWithMembers>> addMembersToGroups(List<Group> groups) {
    return mockRepository.addMembersToGroups(groups);
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
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({'name': 'テストグループ', 'memo': 'テストメモ'});

      final result = await repository.getGroups();

      expect(result.length, 1);
      expect(result[0].id, 'group001');
      expect(result[0].name, 'テストグループ');
      expect(result[0].memo, 'テストメモ');
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

    group('getGroupsWithMembersByMemberId', () {
      Member createTestMember(String memberId) {
        return Member(
          id: memberId,
          displayName: 'テストユーザー',
          email: 'test@example.com',
        );
      }

      Group createTestGroup({
        required String id,
        required String administratorId,
        required String name,
        String? memo,
      }) {
        return Group(
          id: id,
          administratorId: administratorId,
          name: name,
          memo: memo ?? '$nameメモ',
        );
      }

      _TestFirestoreGroupRepository setupMockedRepository({
        required List<Group> adminGroups,
        required List<Group> memberGroups,
        required List<GroupWithMembers> expectedResult,
        required String memberId,
        bool shouldThrowError = false,
      }) {
        final mockRepository = MockFirestoreGroupRepository();

        if (shouldThrowError) {
          when(
            mockRepository.getGroupsWhereUserIsAdmin(memberId),
          ).thenThrow(Exception('Firestore error'));
        } else {
          when(
            mockRepository.getGroupsWhereUserIsAdmin(memberId),
          ).thenAnswer((_) async => adminGroups);
        }

        when(
          mockRepository.getGroupsWhereUserIsMember(memberId),
        ).thenAnswer((_) async => memberGroups);
        when(
          mockRepository.addMembersToGroups(any),
        ).thenAnswer((_) async => expectedResult);

        return _TestFirestoreGroupRepository(
          firestore: mockFirestore,
          mockRepository: mockRepository,
        );
      }

      test('管理者グループとメンバーグループ両方がある場合、重複なしで2件のGroupWithMembersを返す', () async {
        const memberId = 'member001';

        // テストデータ作成
        final adminGroups = [
          createTestGroup(
            id: 'admin-group001',
            administratorId: memberId,
            name: '管理者グループ',
          ),
        ];
        final memberGroups = [
          createTestGroup(
            id: 'member-group001',
            administratorId: 'other-admin',
            name: 'メンバーグループ',
          ),
        ];

        final mockMember = createTestMember(memberId);
        final expectedResult = [
          GroupWithMembers(group: adminGroups.first, members: [mockMember]),
          GroupWithMembers(group: memberGroups.first, members: [mockMember]),
        ];

        // モックセットアップ
        final testRepository = setupMockedRepository(
          adminGroups: adminGroups,
          memberGroups: memberGroups,
          expectedResult: expectedResult,
          memberId: memberId,
        );

        final List<GroupWithMembers> result = await testRepository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result.length, 2);

        // 管理者グループの確認
        final adminGroup = result.firstWhere(
          (g) => g.group.id == 'admin-group001',
        );
        expect(adminGroup.group.name, '管理者グループ');
        expect(adminGroup.group.administratorId, memberId);
        expect(adminGroup.members.length, 1);
        final Member adminGroupMember = adminGroup.members[0];
        expect(adminGroupMember.id, memberId);
        expect(adminGroupMember.displayName, 'テストユーザー');

        // メンバーグループの確認
        final memberGroup = result.firstWhere(
          (g) => g.group.id == 'member-group001',
        );
        expect(memberGroup.group.name, 'メンバーグループ');
        expect(memberGroup.group.administratorId, 'other-admin');
        expect(memberGroup.members.length, 1);
        expect(memberGroup.members[0].id, memberId);
        expect(memberGroup.members[0].displayName, 'テストユーザー');

        // モックが呼ばれたことを確認
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsAdmin(memberId),
        ).called(1);
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsMember(memberId),
        ).called(1);
        verify(testRepository.mockRepository.addMembersToGroups(any)).called(1);
      });

      test('管理者グループのみある場合、1件のGroupWithMembersを返す', () async {
        const memberId = 'member001';

        // テストデータ作成
        final adminGroups = [
          createTestGroup(
            id: 'admin-group001',
            administratorId: memberId,
            name: '管理者グループ',
          ),
        ];
        final memberGroups = <Group>[];

        final mockMember = createTestMember(memberId);
        final expectedResult = [
          GroupWithMembers(group: adminGroups.first, members: [mockMember]),
        ];

        // モックセットアップ
        final testRepository = setupMockedRepository(
          adminGroups: adminGroups,
          memberGroups: memberGroups,
          expectedResult: expectedResult,
          memberId: memberId,
        );

        final List<GroupWithMembers> result = await testRepository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result.length, 1);
        expect(result[0].group.id, 'admin-group001');
        expect(result[0].group.name, '管理者グループ');
        expect(result[0].group.administratorId, memberId);
        expect(result[0].members.length, 1);
        expect(result[0].members[0].id, memberId);
        expect(result[0].members[0].displayName, 'テストユーザー');

        // モックが呼ばれたことを確認
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsAdmin(memberId),
        ).called(1);
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsMember(memberId),
        ).called(1);
        verify(testRepository.mockRepository.addMembersToGroups(any)).called(1);
      });

      test('メンバーグループのみある場合、1件のGroupWithMembersを返す', () async {
        const memberId = 'member001';

        // テストデータ作成
        final adminGroups = <Group>[];
        final memberGroups = [
          createTestGroup(
            id: 'member-group001',
            administratorId: 'other-admin',
            name: 'メンバーグループ',
          ),
        ];

        final mockMember = createTestMember(memberId);
        final expectedResult = [
          GroupWithMembers(group: memberGroups.first, members: [mockMember]),
        ];

        // モックセットアップ
        final testRepository = setupMockedRepository(
          adminGroups: adminGroups,
          memberGroups: memberGroups,
          expectedResult: expectedResult,
          memberId: memberId,
        );

        final List<GroupWithMembers> result = await testRepository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result.length, 1);
        expect(result[0].group.id, 'member-group001');
        expect(result[0].group.name, 'メンバーグループ');
        expect(result[0].group.administratorId, 'other-admin');
        expect(result[0].members.length, 1);
        expect(result[0].members[0].id, memberId);
        expect(result[0].members[0].displayName, 'テストユーザー');

        // モックが呼ばれたことを確認
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsAdmin(memberId),
        ).called(1);
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsMember(memberId),
        ).called(1);
        verify(testRepository.mockRepository.addMembersToGroups(any)).called(1);
      });

      test(
        '管理者グループとメンバーグループ両方で同じグループに関連している場合、重複除去されて1件のGroupWithMembersを返す',
        () async {
          const memberId = 'member001';
          const groupId = 'same-group001';

          // テストデータ作成
          final sameGroup = createTestGroup(
            id: groupId,
            administratorId: memberId,
            name: '同一グループ',
          );
          final adminGroups = [sameGroup];
          final memberGroups = [sameGroup];

          final mockMember = createTestMember(memberId);
          final expectedResult = [
            GroupWithMembers(group: sameGroup, members: [mockMember]),
          ];

          // モックセットアップ
          final testRepository = setupMockedRepository(
            adminGroups: adminGroups,
            memberGroups: memberGroups,
            expectedResult: expectedResult,
            memberId: memberId,
          );

          final result = await testRepository.getGroupsWithMembersByMemberId(
            memberId,
          );

          expect(result.length, 1);
          expect(result[0].group.id, groupId);
          expect(result[0].group.name, '同一グループ');
          expect(result[0].group.administratorId, memberId);
          expect(result[0].members.length, 1);
          expect(result[0].members[0].id, memberId);
          expect(result[0].members[0].displayName, 'テストユーザー');

          // モックが呼ばれたことを確認
          verify(
            testRepository.mockRepository.getGroupsWhereUserIsAdmin(memberId),
          ).called(1);
          verify(
            testRepository.mockRepository.getGroupsWhereUserIsMember(memberId),
          ).called(1);
          verify(
            testRepository.mockRepository.addMembersToGroups(any),
          ).called(1);
        },
      );

      test('管理者・メンバーどちらのグループもない場合、空のリストを返す', () async {
        const memberId = 'member001';

        // テストデータ作成
        final adminGroups = <Group>[];
        final memberGroups = <Group>[];
        final expectedResult = <GroupWithMembers>[];

        // モックセットアップ
        final testRepository = setupMockedRepository(
          adminGroups: adminGroups,
          memberGroups: memberGroups,
          expectedResult: expectedResult,
          memberId: memberId,
        );

        final List<GroupWithMembers> result = await testRepository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result, isEmpty);

        // モックが呼ばれたことを確認
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsAdmin(memberId),
        ).called(1);
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsMember(memberId),
        ).called(1);
        verify(testRepository.mockRepository.addMembersToGroups(any)).called(1);
      });

      test('エラーが発生した場合、空のリストを返す', () async {
        const memberId = 'member001';

        // テストデータ作成（エラーケース）
        final adminGroups = <Group>[];
        final memberGroups = <Group>[];
        final expectedResult = <GroupWithMembers>[];

        // モックセットアップ（エラーケース）
        final testRepository = setupMockedRepository(
          adminGroups: adminGroups,
          memberGroups: memberGroups,
          expectedResult: expectedResult,
          memberId: memberId,
          shouldThrowError: true,
        );

        final List<GroupWithMembers> result = await testRepository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result, isEmpty);

        // エラーが発生したメソッドが呼ばれたことを確認
        verify(
          testRepository.mockRepository.getGroupsWhereUserIsAdmin(memberId),
        ).called(1);
        // エラーが発生した後は他のメソッドは呼ばれない
        verifyNever(
          testRepository.mockRepository.getGroupsWhereUserIsMember(memberId),
        );
        verifyNever(testRepository.mockRepository.addMembersToGroups(any));
      });
    });

    group('getManagedGroupsWithMembersByAdministratorId', () {
      test('管理者IDに基づいてGroupWithMembersのリストを返す', () async {
        const administratorId = 'admin001';

        // getGroupsByAdministratorIdの戻り値を直接モック
        final mockGroups = [
          Group(
            id: 'group001',
            administratorId: administratorId,
            name: 'テストグループ',
            memo: 'テストメモ',
          ),
        ];

        // repositoryのgetGroupsByAdministratorIdをモック
        final mockRepository = MockFirestoreGroupRepository();
        when(
          mockRepository.getGroupsByAdministratorId(administratorId),
        ).thenAnswer((_) async => mockGroups);

        // addMembersToGroupsの戻り値もモック
        final expectedResult = [
          GroupWithMembers(group: mockGroups.first, members: []),
        ];
        when(
          mockRepository.addMembersToGroups(any),
        ).thenAnswer((_) async => expectedResult);

        // 実際のFirestoreRepositoryインスタンスを使用し、必要なメソッドをオーバーライド
        final testRepository = _TestFirestoreGroupRepository(
          firestore: mockFirestore,
          mockRepository: mockRepository,
        );

        final List<GroupWithMembers> result = await testRepository
            .getManagedGroupsWithMembersByAdministratorId(administratorId);

        expect(result, isA<List<GroupWithMembers>>());
        expect(result.length, equals(1));
        expect(result.first.group.id, equals('group001'));
        expect(result.first.group.administratorId, equals(administratorId));
        expect(result.first.members, isEmpty);

        verify(
          mockRepository.getGroupsByAdministratorId(administratorId),
        ).called(1);
        verify(mockRepository.addMembersToGroups(any)).called(1);
      });

      test('エラーが発生した場合、空のリストを返す', () async {
        const administratorId = 'admin001';

        // getGroupsByAdministratorIdでエラーが発生する場合をモック
        final mockRepository = MockFirestoreGroupRepository();
        when(
          mockRepository.getGroupsByAdministratorId(administratorId),
        ).thenThrow(Exception('Firestore error'));

        final testRepository = _TestFirestoreGroupRepository(
          firestore: mockFirestore,
          mockRepository: mockRepository,
        );

        final List<GroupWithMembers> result = await testRepository
            .getManagedGroupsWithMembersByAdministratorId(administratorId);

        expect(result, isEmpty);
        verify(
          mockRepository.getGroupsByAdministratorId(administratorId),
        ).called(1);
      });
    });
  });
}
