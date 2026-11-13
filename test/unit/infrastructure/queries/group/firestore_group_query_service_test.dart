import 'package:memora/infrastructure/services/firestore_account_permissions_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_group_query_service_test.mocks.dart';

@GenerateMocks([
  FirestoreAccountPermissionsSource,
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  group('FirestoreGroupQueryService', () {
    late FirestoreGroupQueryService service;
    late MockFirestoreAccountPermissionsSource permissions;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockGroupsCollection;
    late MockCollectionReference<Map<String, dynamic>>
    mockGroupMembersCollection;
    late MockCollectionReference<Map<String, dynamic>> mockMembersCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockGroupsCollection = MockCollectionReference<Map<String, dynamic>>();
      mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      mockMembersCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      permissions = MockFirestoreAccountPermissionsSource();
      service = FirestoreGroupQueryService(
        firestore: mockFirestore,
        permissions: permissions,
      );
    });

    test('所属と管理グループは本人の認可文書のIDだけから取得する', () async {
      when(permissions.current()).thenAnswer(
        (_) async => FirestoreAccountPermissions({
          'memberId': 'self',
          'memberGroupIds': ['g'],
          'managedGroupIds': ['g'],
        }),
      );
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc('g')).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get())
          .thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn('g');
      when(mockDocumentSnapshot.data()).thenReturn({'name': '所属先'});
      when(mockFirestore.collection('group_members'))
          .thenReturn(mockGroupMembersCollection);
      when(mockGroupMembersCollection.where('groupId', isEqualTo: 'g'))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);
      expect(
        (await service.getGroupsWithMembersByMemberId('self')).single.id,
        'g',
      );
      expect(
        (await service.getManagedGroupsWithMembersByOwnerId('self')).single.id,
        'g',
      );
      verifyNever(
        mockGroupsCollection.where('ownerId', isEqualTo: anyNamed('isEqualTo')),
      );
    });

    test('画面から別人IDを渡しても本人以外の所属を取得しない', () async {
      when(permissions.current()).thenAnswer(
        (_) async => FirestoreAccountPermissions({
          'memberId': 'self',
          'memberGroupIds': <String>[],
          'managedGroupIds': <String>[],
        }),
      );
      await expectLater(
        service.getGroupsWithMembersByMemberId('other'),
        throwsA(isA<FirebaseException>()),
      );
      verifyZeroInteractions(mockFirestore);
    });

    test('未ログインでは所属一覧を取得しない', () async {
      when(permissions.current()).thenAnswer((_) async => null);
      expect(await service.getGroupsWithMembersByMemberId('self'), isEmpty);
      verifyZeroInteractions(mockFirestore);
    });

    test('グループIDでグループとメンバーを正常に取得する', () async {
      const groupId = 'group123';

      // グループの取得
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get())
          .thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn(groupId);
      when(
        mockDocumentSnapshot.data(),
      ).thenReturn({'name': 'テストグループ', 'ownerId': 'owner1', 'memo': 'テストメモ'});

      // グループメンバーの取得
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('group_members'))
          .thenReturn(mockGroupMembersCollection);
      when(mockGroupMembersCollection.where('groupId', isEqualTo: groupId))
          .thenReturn(mockGroupMemberQuery);
      when(mockGroupMemberQuery.get())
          .thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(mockGroupMemberDoc.data())
          .thenReturn({'memberId': 'member1', 'groupId': 'group1'});

      // メンバー詳細の取得
      final mockMemberDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberDetailSnapshot =
          MockDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('members'))
          .thenReturn(mockMembersCollection);
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef);
      when(mockMemberDocRef.get())
          .thenAnswer((_) async => mockMemberDetailSnapshot);
      when(mockMemberDetailSnapshot.exists).thenReturn(true);
      when(mockMemberDetailSnapshot.id).thenReturn('member1');
      when(mockMemberDetailSnapshot.data())
          .thenReturn({'displayName': 'テストメンバー'});

      final result = await service.getGroupWithMembersById(groupId);

      expect(result, isNotNull);
      expect(result!.id, groupId);
      expect(result.name, 'テストグループ');
      expect(result.memo, 'テストメモ');
      expect(result.members, hasLength(1));
      expect(result.members[0].displayName, 'テストメンバー');
    });

    test('グループが存在しない場合、nullを返す', () async {
      const groupId = 'nonexistent';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get())
          .thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(false);

      final result = await service.getGroupWithMembersById(groupId);

      expect(result, isNull);
    });

    test('getGroupWithMembersByIdで例外が発生した場合、取得失敗を伝える', () async {
      const groupId = 'group123';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId))
          .thenThrow(TestException('Firestore error'));

      await expectLater(
        service.getGroupWithMembersById(groupId),
        throwsA(isA<TestException>()),
      );
    });

    test('membersOrderByを指定してメンバーをソート順で取得する', () async {
      const groupId = 'group123';

      // グループの取得
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get())
          .thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn(groupId);
      when(mockDocumentSnapshot.data())
          .thenReturn({'name': 'テストグループ', 'ownerId': 'owner1'});

      // グループメンバーの取得（2人）
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('group_members'))
          .thenReturn(mockGroupMembersCollection);
      when(mockGroupMembersCollection.where('groupId', isEqualTo: groupId))
          .thenReturn(mockGroupMemberQuery);
      when(mockGroupMemberQuery.get())
          .thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs)
          .thenReturn([mockGroupMemberDoc1, mockGroupMemberDoc2]);
      when(mockGroupMemberDoc1.data()).thenReturn({
        'memberId': 'member1',
        'groupId': groupId,
        'orderIndex': 1,
      });
      when(mockGroupMemberDoc2.data()).thenReturn({
        'memberId': 'member2',
        'groupId': groupId,
        'orderIndex': 0,
      });

      // メンバー詳細の取得
      when(mockFirestore.collection('members'))
          .thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(mockMemberDocRef1.get())
          .thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.exists).thenReturn(true);
      when(mockMemberSnapshot1.id).thenReturn('member1');
      when(mockMemberSnapshot1.data()).thenReturn({'displayName': 'Bメンバー'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(mockMemberDocRef2.get())
          .thenAnswer((_) async => mockMemberSnapshot2);
      when(mockMemberSnapshot2.exists).thenReturn(true);
      when(mockMemberSnapshot2.id).thenReturn('member2');
      when(mockMemberSnapshot2.data()).thenReturn({'displayName': 'Aメンバー'});

      final result = await service.getGroupWithMembersById(
        groupId,
        membersOrderBy: [const OrderBy('orderIndex', descending: false)],
      );

      expect(result, isNotNull);
      expect(result!.members, hasLength(2));
      // orderIndexの昇順でソートされていることを確認
      expect(result.members[0].memberId, 'member2');
      expect(result.members[1].memberId, 'member1');
    });

    test('membersOrderByでorderIndexの降順で並ぶ', () async {
      const groupId = 'group123';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId)).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get())
          .thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn(groupId);
      when(mockDocumentSnapshot.data())
          .thenReturn({'name': 'テストグループ', 'ownerId': 'owner1'});

      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockFirestore.collection('group_members'))
          .thenReturn(mockGroupMembersCollection);
      when(mockGroupMembersCollection.where('groupId', isEqualTo: groupId))
          .thenReturn(mockGroupMemberQuery);
      when(mockGroupMemberQuery.get())
          .thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs)
          .thenReturn([mockGroupMemberDoc1, mockGroupMemberDoc2]);
      when(mockGroupMemberDoc1.data()).thenReturn({
        'memberId': 'member1',
        'groupId': groupId,
        'orderIndex': 1,
      });
      when(mockGroupMemberDoc2.data()).thenReturn({
        'memberId': 'member2',
        'groupId': groupId,
        'orderIndex': 0,
      });

      when(mockFirestore.collection('members'))
          .thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(mockMemberDocRef1.get())
          .thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.exists).thenReturn(true);
      when(mockMemberSnapshot1.id).thenReturn('member1');
      when(mockMemberSnapshot1.data()).thenReturn({'displayName': 'Aメンバー'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(mockMemberDocRef2.get())
          .thenAnswer((_) async => mockMemberSnapshot2);
      when(mockMemberSnapshot2.exists).thenReturn(true);
      when(mockMemberSnapshot2.id).thenReturn('member2');
      when(mockMemberSnapshot2.data()).thenReturn({'displayName': 'Bメンバー'});

      final result = await service.getGroupWithMembersById(
        groupId,
        membersOrderBy: [const OrderBy('orderIndex', descending: true)],
      );

      expect(result, isNotNull);
      expect(result!.members, hasLength(2));
      expect(result.members[0].memberId, 'member1');
      expect(result.members[1].memberId, 'member2');
    });
  });
}
