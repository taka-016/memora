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
      late MockDocumentReference<Map<String, dynamic>> mockGroupDocRef;
      late MockDocumentReference<Map<String, dynamic>> mockMemberDocRef;
      late MockDocumentSnapshot<Map<String, dynamic>> mockGroupDocSnapshot;
      late MockDocumentSnapshot<Map<String, dynamic>> mockMemberDocSnapshot;

      setUp(() {
        mockGroupMembersCollection =
            MockCollectionReference<Map<String, dynamic>>();
        mockMembersCollection = MockCollectionReference<Map<String, dynamic>>();
        mockAdminQuery = MockQuery<Map<String, dynamic>>();
        mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
        mockGroupDocRef = MockDocumentReference<Map<String, dynamic>>();
        mockMemberDocRef = MockDocumentReference<Map<String, dynamic>>();
        mockGroupDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
        mockMemberDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockFirestore.collection('group_members'),
        ).thenReturn(mockGroupMembersCollection);
        when(
          mockFirestore.collection('members'),
        ).thenReturn(mockMembersCollection);
      });

      test('管理者グループとメンバーグループ両方がある場合、重複なしで2件のGroupWithMembersを返す', () async {
        const memberId = 'member001';

        // 管理者グループのモック設定
        final mockAdminQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockAdminDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('administratorId', isEqualTo: memberId),
        ).thenReturn(mockAdminQuery);
        when(
          mockAdminQuery.get(),
        ).thenAnswer((_) async => mockAdminQuerySnapshot);
        when(mockAdminQuerySnapshot.docs).thenReturn([mockAdminDoc]);
        when(mockAdminDoc.id).thenReturn('admin-group001');
        when(mockAdminDoc.data()).thenReturn({
          'administratorId': memberId,
          'name': '管理者グループ',
          'memo': '管理者メモ',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        // メンバーグループのモック設定
        final mockMemberQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
        ).thenReturn(mockGroupMembersQuery);
        when(
          mockGroupMembersQuery.get(),
        ).thenAnswer((_) async => mockMemberQuerySnapshot);
        when(mockMemberQuerySnapshot.docs).thenReturn([mockGroupMemberDoc]);
        when(
          mockGroupMemberDoc.data(),
        ).thenReturn({'groupId': 'member-group001', 'memberId': memberId});

        // メンバーグループドキュメントのモック設定
        when(mockCollection.doc('member-group001')).thenReturn(mockGroupDocRef);
        when(
          mockGroupDocRef.get(),
        ).thenAnswer((_) async => mockGroupDocSnapshot);
        when(mockGroupDocSnapshot.exists).thenReturn(true);
        when(mockGroupDocSnapshot.id).thenReturn('member-group001');
        when(mockGroupDocSnapshot.data()).thenReturn({
          'administratorId': 'other-admin',
          'name': 'メンバーグループ',
          'memo': 'メンバーメモ',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        // 各グループのメンバー取得のモック設定（管理者グループ用）
        final mockAdminGroupMemberQuery = MockQuery<Map<String, dynamic>>();
        final mockAdminGroupMemberSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockAdminGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where(
            'groupId',
            isEqualTo: 'admin-group001',
          ),
        ).thenReturn(mockAdminGroupMemberQuery);
        when(
          mockAdminGroupMemberQuery.get(),
        ).thenAnswer((_) async => mockAdminGroupMemberSnapshot);
        when(
          mockAdminGroupMemberSnapshot.docs,
        ).thenReturn([mockAdminGroupMemberDoc]);
        when(
          mockAdminGroupMemberDoc.data(),
        ).thenReturn({'memberId': memberId, 'groupId': 'admin-group001'});

        // 各グループのメンバー取得のモック設定（メンバーグループ用）
        final mockMemberGroupMemberQuery = MockQuery<Map<String, dynamic>>();
        final mockMemberGroupMemberSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockMemberGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where(
            'groupId',
            isEqualTo: 'member-group001',
          ),
        ).thenReturn(mockMemberGroupMemberQuery);
        when(
          mockMemberGroupMemberQuery.get(),
        ).thenAnswer((_) async => mockMemberGroupMemberSnapshot);
        when(
          mockMemberGroupMemberSnapshot.docs,
        ).thenReturn([mockMemberGroupMemberDoc]);
        when(
          mockMemberGroupMemberDoc.data(),
        ).thenReturn({'memberId': memberId, 'groupId': 'member-group001'});

        // メンバー情報のモック設定
        when(mockMembersCollection.doc(memberId)).thenReturn(mockMemberDocRef);
        when(
          mockMemberDocRef.get(),
        ).thenAnswer((_) async => mockMemberDocSnapshot);
        when(mockMemberDocSnapshot.exists).thenReturn(true);
        when(mockMemberDocSnapshot.id).thenReturn(memberId);
        when(
          mockMemberDocSnapshot.data(),
        ).thenReturn({'displayName': 'テストユーザー', 'email': 'test@example.com'});

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

        // 管理者グループのモック設定
        final mockAdminQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockAdminDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('administratorId', isEqualTo: memberId),
        ).thenReturn(mockAdminQuery);
        when(
          mockAdminQuery.get(),
        ).thenAnswer((_) async => mockAdminQuerySnapshot);
        when(mockAdminQuerySnapshot.docs).thenReturn([mockAdminDoc]);
        when(mockAdminDoc.id).thenReturn('admin-group001');
        when(mockAdminDoc.data()).thenReturn({
          'administratorId': memberId,
          'name': '管理者グループ',
          'memo': '管理者メモ',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        // メンバーグループのモック設定（空）
        final mockMemberQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
        ).thenReturn(mockGroupMembersQuery);
        when(
          mockGroupMembersQuery.get(),
        ).thenAnswer((_) async => mockMemberQuerySnapshot);
        when(mockMemberQuerySnapshot.docs).thenReturn([]);

        // 管理者グループのメンバー取得のモック設定
        final mockAdminGroupMemberQuery = MockQuery<Map<String, dynamic>>();
        final mockAdminGroupMemberSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockAdminGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where(
            'groupId',
            isEqualTo: 'admin-group001',
          ),
        ).thenReturn(mockAdminGroupMemberQuery);
        when(
          mockAdminGroupMemberQuery.get(),
        ).thenAnswer((_) async => mockAdminGroupMemberSnapshot);
        when(
          mockAdminGroupMemberSnapshot.docs,
        ).thenReturn([mockAdminGroupMemberDoc]);
        when(
          mockAdminGroupMemberDoc.data(),
        ).thenReturn({'memberId': memberId, 'groupId': 'admin-group001'});

        // メンバー情報のモック設定
        when(mockMembersCollection.doc(memberId)).thenReturn(mockMemberDocRef);
        when(
          mockMemberDocRef.get(),
        ).thenAnswer((_) async => mockMemberDocSnapshot);
        when(mockMemberDocSnapshot.exists).thenReturn(true);
        when(mockMemberDocSnapshot.id).thenReturn(memberId);
        when(
          mockMemberDocSnapshot.data(),
        ).thenReturn({'displayName': 'テストユーザー', 'email': 'test@example.com'});

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

        // 管理者グループのモック設定（空）
        final mockAdminQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('administratorId', isEqualTo: memberId),
        ).thenReturn(mockAdminQuery);
        when(
          mockAdminQuery.get(),
        ).thenAnswer((_) async => mockAdminQuerySnapshot);
        when(mockAdminQuerySnapshot.docs).thenReturn([]);

        // メンバーグループのモック設定
        final mockMemberQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
        ).thenReturn(mockGroupMembersQuery);
        when(
          mockGroupMembersQuery.get(),
        ).thenAnswer((_) async => mockMemberQuerySnapshot);
        when(mockMemberQuerySnapshot.docs).thenReturn([mockGroupMemberDoc]);
        when(
          mockGroupMemberDoc.data(),
        ).thenReturn({'groupId': 'member-group001', 'memberId': memberId});

        // メンバーグループドキュメントのモック設定
        when(mockCollection.doc('member-group001')).thenReturn(mockGroupDocRef);
        when(
          mockGroupDocRef.get(),
        ).thenAnswer((_) async => mockGroupDocSnapshot);
        when(mockGroupDocSnapshot.exists).thenReturn(true);
        when(mockGroupDocSnapshot.id).thenReturn('member-group001');
        when(mockGroupDocSnapshot.data()).thenReturn({
          'administratorId': 'other-admin',
          'name': 'メンバーグループ',
          'memo': 'メンバーメモ',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        // メンバーグループのメンバー取得のモック設定
        final mockMemberGroupMemberQuery = MockQuery<Map<String, dynamic>>();
        final mockMemberGroupMemberSnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();
        final mockMemberGroupMemberDoc =
            MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where(
            'groupId',
            isEqualTo: 'member-group001',
          ),
        ).thenReturn(mockMemberGroupMemberQuery);
        when(
          mockMemberGroupMemberQuery.get(),
        ).thenAnswer((_) async => mockMemberGroupMemberSnapshot);
        when(
          mockMemberGroupMemberSnapshot.docs,
        ).thenReturn([mockMemberGroupMemberDoc]);
        when(
          mockMemberGroupMemberDoc.data(),
        ).thenReturn({'memberId': memberId, 'groupId': 'member-group001'});

        // メンバー情報のモック設定
        when(mockMembersCollection.doc(memberId)).thenReturn(mockMemberDocRef);
        when(
          mockMemberDocRef.get(),
        ).thenAnswer((_) async => mockMemberDocSnapshot);
        when(mockMemberDocSnapshot.exists).thenReturn(true);
        when(mockMemberDocSnapshot.id).thenReturn(memberId);
        when(
          mockMemberDocSnapshot.data(),
        ).thenReturn({'displayName': 'テストユーザー', 'email': 'test@example.com'});

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

          // 管理者グループのモック設定
          final mockAdminQuerySnapshot =
              MockQuerySnapshot<Map<String, dynamic>>();
          final mockAdminDoc =
              MockQueryDocumentSnapshot<Map<String, dynamic>>();

          when(
            mockCollection.where('administratorId', isEqualTo: memberId),
          ).thenReturn(mockAdminQuery);
          when(
            mockAdminQuery.get(),
          ).thenAnswer((_) async => mockAdminQuerySnapshot);
          when(mockAdminQuerySnapshot.docs).thenReturn([mockAdminDoc]);
          when(mockAdminDoc.id).thenReturn(groupId);
          when(mockAdminDoc.data()).thenReturn({
            'administratorId': memberId,
            'name': '同一グループ',
            'memo': '同一グループメモ',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });

          // メンバーグループのモック設定
          final mockMemberQuerySnapshot =
              MockQuerySnapshot<Map<String, dynamic>>();
          final mockGroupMemberDoc =
              MockQueryDocumentSnapshot<Map<String, dynamic>>();

          when(
            mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
          ).thenReturn(mockGroupMembersQuery);
          when(
            mockGroupMembersQuery.get(),
          ).thenAnswer((_) async => mockMemberQuerySnapshot);
          when(mockMemberQuerySnapshot.docs).thenReturn([mockGroupMemberDoc]);
          when(
            mockGroupMemberDoc.data(),
          ).thenReturn({'groupId': groupId, 'memberId': memberId});

          // 同一グループドキュメントのモック設定
          when(mockCollection.doc(groupId)).thenReturn(mockGroupDocRef);
          when(
            mockGroupDocRef.get(),
          ).thenAnswer((_) async => mockGroupDocSnapshot);
          when(mockGroupDocSnapshot.exists).thenReturn(true);
          when(mockGroupDocSnapshot.id).thenReturn(groupId);
          when(mockGroupDocSnapshot.data()).thenReturn({
            'administratorId': memberId,
            'name': '同一グループ',
            'memo': '同一グループメモ',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });

          // グループのメンバー取得のモック設定
          final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
          final mockGroupMemberSnapshot =
              MockQuerySnapshot<Map<String, dynamic>>();
          final mockGroupMemberDocForMember =
              MockQueryDocumentSnapshot<Map<String, dynamic>>();

          when(
            mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
          ).thenReturn(mockGroupMemberQuery);
          when(
            mockGroupMemberQuery.get(),
          ).thenAnswer((_) async => mockGroupMemberSnapshot);
          when(
            mockGroupMemberSnapshot.docs,
          ).thenReturn([mockGroupMemberDocForMember]);
          when(
            mockGroupMemberDocForMember.data(),
          ).thenReturn({'memberId': memberId, 'groupId': groupId});

          // メンバー情報のモック設定
          when(
            mockMembersCollection.doc(memberId),
          ).thenReturn(mockMemberDocRef);
          when(
            mockMemberDocRef.get(),
          ).thenAnswer((_) async => mockMemberDocSnapshot);
          when(mockMemberDocSnapshot.exists).thenReturn(true);
          when(mockMemberDocSnapshot.id).thenReturn(memberId);
          when(
            mockMemberDocSnapshot.data(),
          ).thenReturn({'displayName': 'テストユーザー', 'email': 'test@example.com'});

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

        // 管理者グループのモック設定（空）
        final mockAdminQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockCollection.where('administratorId', isEqualTo: memberId),
        ).thenReturn(mockAdminQuery);
        when(
          mockAdminQuery.get(),
        ).thenAnswer((_) async => mockAdminQuerySnapshot);
        when(mockAdminQuerySnapshot.docs).thenReturn([]);

        // メンバーグループのモック設定（空）
        final mockMemberQuerySnapshot =
            MockQuerySnapshot<Map<String, dynamic>>();

        when(
          mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
        ).thenReturn(mockGroupMembersQuery);
        when(
          mockGroupMembersQuery.get(),
        ).thenAnswer((_) async => mockMemberQuerySnapshot);
        when(mockMemberQuerySnapshot.docs).thenReturn([]);

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
