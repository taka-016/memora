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
      late MockCollectionReference<Map<String, dynamic>>
      mockGroupMembersCollection;
      late MockCollectionReference<Map<String, dynamic>> mockMembersCollection;
      late MockQuery<Map<String, dynamic>> mockAdminQuery;
      late MockQuery<Map<String, dynamic>> mockGroupMembersQuery;

      setUp(() {
        mockGroupMembersCollection =
            MockCollectionReference<Map<String, dynamic>>();
        mockMembersCollection = MockCollectionReference<Map<String, dynamic>>();
        mockAdminQuery = MockQuery<Map<String, dynamic>>();
        mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
        when(
          mockFirestore.collection('group_members'),
        ).thenReturn(mockGroupMembersCollection);
        when(
          mockFirestore.collection('members'),
        ).thenReturn(mockMembersCollection);
      });

      void mockAdminGroup({
        required String memberId,
        required String groupId,
        required String groupName,
        required String memo,
        required MockCollectionReference<Map<String, dynamic>> mockCollection,
        required MockQuery<Map<String, dynamic>> mockAdminQuery,
        List<MockQueryDocumentSnapshot<Map<String, dynamic>>>? docs,
      }) {
        final mockAdminQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        when(
          mockCollection.where('administratorId', isEqualTo: memberId),
        ).thenReturn(mockAdminQuery);
        when(
          mockAdminQuery.get(),
        ).thenAnswer((_) async => mockAdminQuerySnapshot);
        when(mockAdminQuerySnapshot.docs).thenReturn(docs ?? []);
        if (docs != null && docs.isNotEmpty) {
          when(docs[0].id).thenReturn(groupId);
          when(docs[0].data()).thenReturn({
            'administratorId': memberId,
            'name': groupName,
            'memo': memo,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      void mockMemberGroup({
        required String memberId,
        required String groupId,
        required MockCollectionReference<Map<String, dynamic>>
        mockGroupMembersCollection,
        required MockQuery<Map<String, dynamic>> mockGroupMembersQuery,
        List<MockQueryDocumentSnapshot<Map<String, dynamic>>>? docs,
      }) {
        final mockMemberQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        when(
          mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
        ).thenReturn(mockGroupMembersQuery);
        when(
          mockGroupMembersQuery.get(),
        ).thenAnswer((_) async => mockMemberQuerySnapshot);
        when(mockMemberQuerySnapshot.docs).thenReturn(docs ?? []);
        if (docs != null && docs.isNotEmpty) {
          when(
            docs[0].data(),
          ).thenReturn({'groupId': groupId, 'memberId': memberId});
        }
      }

      void mockGroupDoc({
        required String groupId,
        required String adminId,
        required String groupName,
        required String memo,
        required MockCollectionReference<Map<String, dynamic>> mockCollection,
        MockDocumentReference<Map<String, dynamic>>? mockGroupDocRef,
        MockDocumentSnapshot<Map<String, dynamic>>? mockGroupDocSnapshot,
      }) {
        final docRef =
            mockGroupDocRef ?? MockDocumentReference<Map<String, dynamic>>();
        final docSnapshot =
            mockGroupDocSnapshot ??
            MockDocumentSnapshot<Map<String, dynamic>>();
        when(mockCollection.doc(groupId)).thenReturn(docRef);
        when(docRef.get()).thenAnswer((_) async => docSnapshot);
        when(docSnapshot.exists).thenReturn(true);
        when(docSnapshot.id).thenReturn(groupId);
        when(docSnapshot.data()).thenReturn({
          'administratorId': adminId,
          'name': groupName,
          'memo': memo,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      void mockGroupMembers({
        required String groupId,
        required String memberId,
        required MockCollectionReference<Map<String, dynamic>>
        mockGroupMembersCollection,
        List<MockQueryDocumentSnapshot<Map<String, dynamic>>>? docs,
      }) {
        final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
        final mockGroupMemberSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        when(
          mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
        ).thenReturn(mockGroupMemberQuery);
        when(
          mockGroupMemberQuery.get(),
        ).thenAnswer((_) async => mockGroupMemberSnapshot);
        when(mockGroupMemberSnapshot.docs).thenReturn(docs ?? []);
        if (docs != null && docs.isNotEmpty) {
          when(
            docs[0].data(),
          ).thenReturn({'memberId': memberId, 'groupId': groupId});
        }
      }

      void mockMemberInfo({
        required String memberId,
        required MockCollectionReference<Map<String, dynamic>>
        mockMembersCollection,
        MockDocumentReference<Map<String, dynamic>>? mockMemberDocRef,
        MockDocumentSnapshot<Map<String, dynamic>>? mockMemberDocSnapshot,
      }) {
        final docRef =
            mockMemberDocRef ?? MockDocumentReference<Map<String, dynamic>>();
        final docSnapshot =
            mockMemberDocSnapshot ??
            MockDocumentSnapshot<Map<String, dynamic>>();
        when(mockMembersCollection.doc(memberId)).thenReturn(docRef);
        when(docRef.get()).thenAnswer((_) async => docSnapshot);
        when(docSnapshot.exists).thenReturn(true);
        when(docSnapshot.id).thenReturn(memberId);
        when(
          docSnapshot.data(),
        ).thenReturn({'displayName': 'テストユーザー', 'email': 'test@example.com'});
      }

      test('管理者グループとメンバーグループ両方がある場合、重複なしで2件のGroupWithMembersを返す', () async {
        const memberId = 'member001';
        // 管理者グループ
        final mockAdminDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockAdminGroup(
          memberId: memberId,
          groupId: 'admin-group001',
          groupName: '管理者グループ',
          memo: '管理者メモ',
          mockCollection: mockCollection,
          mockAdminQuery: mockAdminQuery,
          docs: [mockAdminDoc],
        );
        // メンバーグループ
        final mockGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockMemberGroup(
          memberId: memberId,
          groupId: 'member-group001',
          mockGroupMembersCollection: mockGroupMembersCollection,
          mockGroupMembersQuery: mockGroupMembersQuery,
          docs: [mockGroupMemberDoc],
        );
        // メンバーグループドキュメント
        mockGroupDoc(
          groupId: 'member-group001',
          adminId: 'other-admin',
          groupName: 'メンバーグループ',
          memo: 'メンバーメモ',
          mockCollection: mockCollection,
        );
        // 管理者グループのメンバー
        final mockAdminGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockGroupMembers(
          groupId: 'admin-group001',
          memberId: memberId,
          mockGroupMembersCollection: mockGroupMembersCollection,
          docs: [mockAdminGroupMemberDoc],
        );
        // メンバーグループのメンバー
        final mockMemberGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockGroupMembers(
          groupId: 'member-group001',
          memberId: memberId,
          mockGroupMembersCollection: mockGroupMembersCollection,
          docs: [mockMemberGroupMemberDoc],
        );
        // メンバー情報
        mockMemberInfo(
          memberId: memberId,
          mockMembersCollection: mockMembersCollection,
        );

        final List<GroupWithMembers> result = await repository
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
      });

      test('管理者グループのみある場合、1件のGroupWithMembersを返す', () async {
        const memberId = 'member001';
        // 管理者グループ
        final mockAdminDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockAdminGroup(
          memberId: memberId,
          groupId: 'admin-group001',
          groupName: '管理者グループ',
          memo: '管理者メモ',
          mockCollection: mockCollection,
          mockAdminQuery: mockAdminQuery,
          docs: [mockAdminDoc],
        );
        // メンバーグループ（空）
        mockMemberGroup(
          memberId: memberId,
          groupId: '',
          mockGroupMembersCollection: mockGroupMembersCollection,
          mockGroupMembersQuery: mockGroupMembersQuery,
          docs: [],
        );
        // 管理者グループのメンバー
        final mockAdminGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockGroupMembers(
          groupId: 'admin-group001',
          memberId: memberId,
          mockGroupMembersCollection: mockGroupMembersCollection,
          docs: [mockAdminGroupMemberDoc],
        );
        // メンバー情報
        mockMemberInfo(
          memberId: memberId,
          mockMembersCollection: mockMembersCollection,
        );

        final List<GroupWithMembers> result = await repository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result.length, 1);
        expect(result[0].group.id, 'admin-group001');
        expect(result[0].group.name, '管理者グループ');
        expect(result[0].group.administratorId, memberId);
        expect(result[0].members.length, 1);
        expect(result[0].members[0].id, memberId);
        expect(result[0].members[0].displayName, 'テストユーザー');
      });

      test('メンバーグループのみある場合、1件のGroupWithMembersを返す', () async {
        const memberId = 'member001';
        // 管理者グループ（空）
        mockAdminGroup(
          memberId: memberId,
          groupId: '',
          groupName: '',
          memo: '',
          mockCollection: mockCollection,
          mockAdminQuery: mockAdminQuery,
          docs: [],
        );
        // メンバーグループ
        final mockGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockMemberGroup(
          memberId: memberId,
          groupId: 'member-group001',
          mockGroupMembersCollection: mockGroupMembersCollection,
          mockGroupMembersQuery: mockGroupMembersQuery,
          docs: [mockGroupMemberDoc],
        );
        // メンバーグループドキュメント
        mockGroupDoc(
          groupId: 'member-group001',
          adminId: 'other-admin',
          groupName: 'メンバーグループ',
          memo: 'メンバーメモ',
          mockCollection: mockCollection,
        );
        // メンバーグループのメンバー
        final mockMemberGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();
        mockGroupMembers(
          groupId: 'member-group001',
          memberId: memberId,
          mockGroupMembersCollection: mockGroupMembersCollection,
          docs: [mockMemberGroupMemberDoc],
        );
        // メンバー情報
        mockMemberInfo(
          memberId: memberId,
          mockMembersCollection: mockMembersCollection,
        );

        final List<GroupWithMembers> result = await repository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result.length, 1);
        expect(result[0].group.id, 'member-group001');
        expect(result[0].group.name, 'メンバーグループ');
        expect(result[0].group.administratorId, 'other-admin');
        expect(result[0].members.length, 1);
        expect(result[0].members[0].id, memberId);
        expect(result[0].members[0].displayName, 'テストユーザー');
      });

      test(
        '管理者グループとメンバーグループ両方で同じグループに関連している場合、重複除去されて1件のGroupWithMembersを返す',
        () async {
          const memberId = 'member001';
          const groupId = 'same-group001';
          // 管理者グループ
          final mockAdminDoc =
              MockQueryDocumentSnapshot<Map<String, dynamic>>();
          mockAdminGroup(
            memberId: memberId,
            groupId: groupId,
            groupName: '同一グループ',
            memo: '同一グループメモ',
            mockCollection: mockCollection,
            mockAdminQuery: mockAdminQuery,
            docs: [mockAdminDoc],
          );
          // メンバーグループ
          final mockGroupMemberDoc =
              MockQueryDocumentSnapshot<Map<String, dynamic>>();
          mockMemberGroup(
            memberId: memberId,
            groupId: groupId,
            mockGroupMembersCollection: mockGroupMembersCollection,
            mockGroupMembersQuery: mockGroupMembersQuery,
            docs: [mockGroupMemberDoc],
          );
          // 同一グループドキュメント
          mockGroupDoc(
            groupId: groupId,
            adminId: memberId,
            groupName: '同一グループ',
            memo: '同一グループメモ',
            mockCollection: mockCollection,
          );
          // グループのメンバー
          final mockGroupMemberDocForMember =
              MockQueryDocumentSnapshot<Map<String, dynamic>>();
          mockGroupMembers(
            groupId: groupId,
            memberId: memberId,
            mockGroupMembersCollection: mockGroupMembersCollection,
            docs: [mockGroupMemberDocForMember],
          );
          // メンバー情報
          mockMemberInfo(
            memberId: memberId,
            mockMembersCollection: mockMembersCollection,
          );

          final result = await repository.getGroupsWithMembersByMemberId(
            memberId,
          );

          expect(result.length, 1);
          expect(result[0].group.id, groupId);
          expect(result[0].group.name, '同一グループ');
          expect(result[0].group.administratorId, memberId);
          expect(result[0].members.length, 1);
          expect(result[0].members[0].id, memberId);
          expect(result[0].members[0].displayName, 'テストユーザー');
        },
      );

      test('管理者・メンバーどちらのグループもない場合、空のリストを返す', () async {
        const memberId = 'member001';
        // 管理者グループ（空）
        mockAdminGroup(
          memberId: memberId,
          groupId: '',
          groupName: '',
          memo: '',
          mockCollection: mockCollection,
          mockAdminQuery: mockAdminQuery,
          docs: [],
        );
        // メンバーグループ（空）
        mockMemberGroup(
          memberId: memberId,
          groupId: '',
          mockGroupMembersCollection: mockGroupMembersCollection,
          mockGroupMembersQuery: mockGroupMembersQuery,
          docs: [],
        );

        final List<GroupWithMembers> result = await repository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result, isEmpty);
      });

      test('エラーが発生した場合、空のリストを返す', () async {
        const memberId = 'member001';
        when(
          mockCollection.where('administratorId', isEqualTo: memberId),
        ).thenReturn(mockAdminQuery);
        when(mockAdminQuery.get()).thenThrow(Exception('Firestore error'));

        final List<GroupWithMembers> result = await repository
            .getGroupsWithMembersByMemberId(memberId);

        expect(result, isEmpty);
      });
    });
  });
}
