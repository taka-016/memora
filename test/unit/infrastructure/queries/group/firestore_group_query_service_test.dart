import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_group_query_service_test.mocks.dart';

@GenerateMocks([
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
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockGroupsCollection;
    late MockCollectionReference<Map<String, dynamic>>
    mockGroupMembersCollection;
    late MockCollectionReference<Map<String, dynamic>> mockMembersCollection;
    late MockQuery<Map<String, dynamic>> mockQuery;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>>
    mockQueryDocumentSnapshot;
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
      mockQueryDocumentSnapshot =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();
      mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();

      service = FirestoreGroupQueryService(firestore: mockFirestore);
    });

    test('管理者グループとメンバーグループを正常に取得する', () async {
      const memberId = 'member123';

      // 管理者として参加しているグループのモック設定
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(
        mockGroupsCollection.where('ownerId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot.id).thenReturn('group1');
      when(
        mockQueryDocumentSnapshot.data(),
      ).thenReturn({'name': '管理者グループ', 'ownerId': memberId, 'memo': '管理者メモ'});

      // メンバーとして参加しているグループのモック設定
      final mockGroupMemberQuery1 = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot1 =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMemberQuery1);
      when(
        mockGroupMemberQuery1.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot1);
      when(mockGroupMemberSnapshot1.docs).thenReturn([mockGroupMemberDoc1]);
      when(mockGroupMemberDoc1.data()).thenReturn({'groupId': 'group2'});

      final mockGroupDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(
        mockGroupsCollection.doc('group2'),
      ).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get()).thenAnswer((_) async => mockGroupDoc);
      when(mockGroupDoc.exists).thenReturn(true);
      when(mockGroupDoc.id).thenReturn('group2');
      when(mockGroupDoc.data()).thenReturn({
        'name': 'メンバーグループ',
        'ownerId': 'other_owner',
        'memo': 'メンバーメモ',
      });

      // グループのメンバー取得（group1）
      final mockGroupMemberQuery2 = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot2 =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockGroupMemberQuery2);
      when(
        mockGroupMemberQuery2.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot2);
      when(mockGroupMemberSnapshot2.docs).thenReturn([mockGroupMemberDoc2]);
      when(
        mockGroupMemberDoc2.data(),
      ).thenReturn({'memberId': 'member1', 'groupId': 'group1'});

      // グループのメンバー取得（group2）
      final mockGroupMemberQuery3 = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot3 =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc3 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group2'),
      ).thenReturn(mockGroupMemberQuery3);
      when(
        mockGroupMemberQuery3.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot3);
      when(mockGroupMemberSnapshot3.docs).thenReturn([mockGroupMemberDoc3]);
      when(
        mockGroupMemberDoc3.data(),
      ).thenReturn({'memberId': 'member2', 'groupId': 'group2'});

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(
        mockMemberDocRef1.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.exists).thenReturn(true);
      when(mockMemberSnapshot1.id).thenReturn('member1');
      when(mockMemberSnapshot1.data()).thenReturn({'displayName': 'メンバー1'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(
        mockMemberDocRef2.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2);
      when(mockMemberSnapshot2.exists).thenReturn(true);
      when(mockMemberSnapshot2.id).thenReturn('member2');
      when(mockMemberSnapshot2.data()).thenReturn({'displayName': 'メンバー2'});

      final result = await service.getGroupsWithMembersByMemberId(memberId);

      expect(result, hasLength(2));
      expect(result[0].id, 'group1');
      expect(result[0].name, '管理者グループ');
      expect(result[0].memo, '管理者メモ');
      expect(result[1].id, 'group2');
      expect(result[1].name, 'メンバーグループ');
      expect(result[1].memo, 'メンバーメモ');
    });

    test('例外が発生した場合、空のリストを返す', () async {
      const memberId = 'member123';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(
        mockGroupsCollection.where('ownerId', isEqualTo: memberId),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getGroupsWithMembersByMemberId(memberId);

      expect(result, isEmpty);
    });

    test('指定されたオーナーIDで管理しているグループとメンバー情報を正常に取得する', () async {
      const ownerId = 'owner123';

      // 管理者として参加しているグループのモック設定
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(
        mockGroupsCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot.id).thenReturn('group1');
      when(mockQueryDocumentSnapshot.data()).thenReturn({
        'name': '管理者グループ',
        'ownerId': ownerId,
        'memo': '管理者グループのメモ',
      });

      // グループのメンバー取得
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(
        mockGroupMemberDoc.data(),
      ).thenReturn({'memberId': 'member1', 'groupId': 'group1'});

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);
      when(
        mockMembersCollection.doc('member1'),
      ).thenReturn(mockDocumentReference);
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn('member1');
      when(mockDocumentSnapshot.data()).thenReturn({'displayName': 'テストメンバー'});

      final result = await service.getManagedGroupsWithMembersByOwnerId(
        ownerId,
      );

      expect(result, hasLength(1));
      expect(result[0].id, 'group1');
      expect(result[0].name, '管理者グループ');
      expect(result[0].memo, '管理者グループのメモ');
      expect(result[0].members, hasLength(1));
      expect(result[0].members[0].displayName, 'テストメンバー');
    });

    test('例外が発生した場合、空のリストを返す', () async {
      const ownerId = 'owner123';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(
        mockGroupsCollection.where('ownerId', isEqualTo: ownerId),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getManagedGroupsWithMembersByOwnerId(
        ownerId,
      );

      expect(result, isEmpty);
    });

    test('groupsOrderByとmembersOrderByを指定してグループとメンバーをソート順で取得する', () async {
      const memberId = 'member123';

      // 管理者として参加しているグループのモック設定
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);

      // 2つのグループを返す（名前降順：Bグループ、Aグループ）
      when(
        mockGroupsCollection.where('ownerId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      final mockGroupDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockQuerySnapshot.docs).thenReturn([mockGroupDoc1, mockGroupDoc2]);
      when(mockGroupDoc1.id).thenReturn('group2');
      when(
        mockGroupDoc1.data(),
      ).thenReturn({'name': 'Bグループ', 'ownerId': memberId});
      when(mockGroupDoc2.id).thenReturn('group1');
      when(
        mockGroupDoc2.data(),
      ).thenReturn({'name': 'Aグループ', 'ownerId': memberId});

      // メンバーとして参加しているグループはなし
      final mockGroupMemberQuery1 = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot1 =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMemberQuery1);
      when(
        mockGroupMemberQuery1.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot1);
      when(mockGroupMemberSnapshot1.docs).thenReturn([]);

      // グループのメンバー取得（group1）
      final mockGroupMemberQuery2 = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot2 =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockGroupMemberQuery2);
      when(
        mockGroupMemberQuery2.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot2);
      when(mockGroupMemberSnapshot2.docs).thenReturn([mockGroupMemberDoc2]);
      when(
        mockGroupMemberDoc2.data(),
      ).thenReturn({'memberId': 'member1', 'groupId': 'group1'});

      // グループのメンバー取得（group2）
      final mockGroupMemberQuery3 = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot3 =
          MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc3 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group2'),
      ).thenReturn(mockGroupMemberQuery3);
      when(
        mockGroupMemberQuery3.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot3);
      when(mockGroupMemberSnapshot3.docs).thenReturn([mockGroupMemberDoc3]);
      when(
        mockGroupMemberDoc3.data(),
      ).thenReturn({'memberId': 'member2', 'groupId': 'group2'});

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(
        mockMemberDocRef1.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.exists).thenReturn(true);
      when(mockMemberSnapshot1.id).thenReturn('member1');
      when(mockMemberSnapshot1.data()).thenReturn({'displayName': 'Aメンバー'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(
        mockMemberDocRef2.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2);
      when(mockMemberSnapshot2.exists).thenReturn(true);
      when(mockMemberSnapshot2.id).thenReturn('member2');
      when(mockMemberSnapshot2.data()).thenReturn({'displayName': 'Bメンバー'});

      final result = await service.getGroupsWithMembersByMemberId(
        memberId,
        groupsOrderBy: [const OrderBy('name', descending: false)],
        membersOrderBy: [const OrderBy('orderIndex', descending: false)],
      );

      expect(result, hasLength(2));
      // メモリ内ソートでAグループ、Bグループの順になることを確認
      expect(result[0].id, 'group1');
      expect(result[0].name, 'Aグループ');
      expect(result[1].id, 'group2');
      expect(result[1].name, 'Bグループ');
    });

    test('groupsOrderByとmembersOrderByを指定して管理グループとメンバーをソート順で取得する', () async {
      const ownerId = 'owner123';

      // 管理者として参加しているグループのモック設定
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);

      final mockOwnerQuery = MockQuery<Map<String, dynamic>>();
      final mockOwnerQueryOrderBy = MockQuery<Map<String, dynamic>>();

      when(
        mockGroupsCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockOwnerQuery);
      when(
        mockOwnerQuery.orderBy('name', descending: false),
      ).thenReturn(mockOwnerQueryOrderBy);
      when(
        mockOwnerQueryOrderBy.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot.id).thenReturn('group1');
      when(
        mockQueryDocumentSnapshot.data(),
      ).thenReturn({'name': '管理者グループ', 'ownerId': ownerId});

      // グループのメンバー取得
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(
        mockGroupMemberDoc.data(),
      ).thenReturn({'memberId': 'member1', 'groupId': 'group1'});

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);
      when(
        mockMembersCollection.doc('member1'),
      ).thenReturn(mockDocumentReference);
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn('member1');
      when(mockDocumentSnapshot.data()).thenReturn({'displayName': 'テストメンバー'});

      final result = await service.getManagedGroupsWithMembersByOwnerId(
        ownerId,
        groupsOrderBy: [const OrderBy('name', descending: false)],
        membersOrderBy: [const OrderBy('orderIndex', descending: true)],
      );

      expect(result, hasLength(1));
      expect(result[0].id, 'group1');
      expect(result[0].name, '管理者グループ');
      expect(result[0].members, hasLength(1));
      expect(result[0].members[0].displayName, 'テストメンバー');

      // groupsOrderByで'name'の昇順でソートされることを確認
      verify(mockOwnerQuery.orderBy('name', descending: false)).called(1);
    });

    test('グループIDでグループとメンバーを正常に取得する', () async {
      const groupId = 'group123';

      // グループの取得
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId)).thenReturn(mockDocumentReference);
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
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

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(
        mockGroupMemberDoc.data(),
      ).thenReturn({'memberId': 'member1', 'groupId': 'group1'});

      // メンバー詳細の取得
      final mockMemberDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberDetailSnapshot =
          MockDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef);
      when(
        mockMemberDocRef.get(),
      ).thenAnswer((_) async => mockMemberDetailSnapshot);
      when(mockMemberDetailSnapshot.exists).thenReturn(true);
      when(mockMemberDetailSnapshot.id).thenReturn('member1');
      when(
        mockMemberDetailSnapshot.data(),
      ).thenReturn({'displayName': 'テストメンバー'});

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
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(false);

      final result = await service.getGroupWithMembersById(groupId);

      expect(result, isNull);
    });

    test('getGroupWithMembersByIdで例外が発生した場合、nullを返す', () async {
      const groupId = 'group123';

      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(
        mockGroupsCollection.doc(groupId),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getGroupWithMembersById(groupId);

      expect(result, isNull);
    });

    test('membersOrderByを指定してメンバーをソート順で取得する', () async {
      const groupId = 'group123';

      // グループの取得
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);
      when(mockGroupsCollection.doc(groupId)).thenReturn(mockDocumentReference);
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn(groupId);
      when(
        mockDocumentSnapshot.data(),
      ).thenReturn({'name': 'テストグループ', 'ownerId': 'owner1'});

      // グループメンバーの取得（2人）
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(
        mockGroupMemberSnapshot.docs,
      ).thenReturn([mockGroupMemberDoc1, mockGroupMemberDoc2]);
      when(mockGroupMemberDoc1.data()).thenReturn({
        'memberId': 'member1',
        'groupId': 'group1',
        'orderIndex': 1,
      });
      when(mockGroupMemberDoc2.data()).thenReturn({
        'memberId': 'member2',
        'groupId': 'group2',
        'orderIndex': 0,
      });

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(
        mockMemberDocRef1.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.exists).thenReturn(true);
      when(mockMemberSnapshot1.id).thenReturn('member1');
      when(mockMemberSnapshot1.data()).thenReturn({'displayName': 'Bメンバー'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(
        mockMemberDocRef2.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2);
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
      when(
        mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.id).thenReturn(groupId);
      when(
        mockDocumentSnapshot.data(),
      ).thenReturn({'name': 'テストグループ', 'ownerId': 'owner1'});

      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc1 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc2 =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(
        mockGroupMemberSnapshot.docs,
      ).thenReturn([mockGroupMemberDoc1, mockGroupMemberDoc2]);
      when(mockGroupMemberDoc1.data()).thenReturn({
        'memberId': 'member1',
        'groupId': 'group1',
        'orderIndex': 1,
      });
      when(mockGroupMemberDoc2.data()).thenReturn({
        'memberId': 'member2',
        'groupId': 'group2',
        'orderIndex': 0,
      });

      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(
        mockMemberDocRef1.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.exists).thenReturn(true);
      when(mockMemberSnapshot1.id).thenReturn('member1');
      when(mockMemberSnapshot1.data()).thenReturn({'displayName': 'Aメンバー'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(
        mockMemberDocRef2.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2);
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
