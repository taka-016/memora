import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/services/firestore_group_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import '../../../helpers/test_exception.dart';

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
      ).thenReturn({'name': '管理者グループ', 'ownerId': memberId});

      // メンバーとして参加しているグループのモック設定
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockGroupMemberDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs).thenReturn([mockGroupMemberDoc]);
      when(mockGroupMemberDoc.data()).thenReturn({'groupId': 'group2'});

      // グループ詳細の取得（group2）
      final mockGroupDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(
        mockGroupsCollection.doc('group2'),
      ).thenReturn(mockDocumentReference);
      when(mockDocumentReference.get()).thenAnswer((_) async => mockGroupDoc);
      when(mockGroupDoc.exists).thenReturn(true);
      when(
        mockGroupDoc.data(),
      ).thenReturn({'name': 'メンバーグループ', 'ownerId': 'other_owner'});

      // グループのメンバー取得（group1）
      final mockMemberQuery1 = MockQuery<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
      final mockMemberDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockMemberQuery1);
      when(mockMemberQuery1.get()).thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.docs).thenReturn([mockMemberDoc1]);
      when(mockMemberDoc1.data()).thenReturn({'memberId': 'member1'});

      // グループのメンバー取得（group2）
      final mockMemberQuery2 = MockQuery<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
      final mockMemberDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group2'),
      ).thenReturn(mockMemberQuery2);
      when(mockMemberQuery2.get()).thenAnswer((_) async => mockMemberSnapshot2);
      when(mockMemberSnapshot2.docs).thenReturn([mockMemberDoc2]);
      when(mockMemberDoc2.data()).thenReturn({'memberId': 'member2'});

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1Detail =
          MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(
        mockMemberDocRef1.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1Detail);
      when(mockMemberSnapshot1Detail.exists).thenReturn(true);
      when(mockMemberSnapshot1Detail.id).thenReturn('member1');
      when(
        mockMemberSnapshot1Detail.data(),
      ).thenReturn({'displayName': 'メンバー1'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2Detail =
          MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(
        mockMemberDocRef2.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2Detail);
      when(mockMemberSnapshot2Detail.exists).thenReturn(true);
      when(mockMemberSnapshot2Detail.id).thenReturn('member2');
      when(
        mockMemberSnapshot2Detail.data(),
      ).thenReturn({'displayName': 'メンバー2'});

      final result = await service.getGroupsWithMembersByMemberId(memberId);

      expect(result, hasLength(2));
      expect(result[0].groupId, 'group1');
      expect(result[0].groupName, '管理者グループ');
      expect(result[1].groupId, 'group2');
      expect(result[1].groupName, 'メンバーグループ');
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
      when(
        mockQueryDocumentSnapshot.data(),
      ).thenReturn({'name': '管理者グループ', 'ownerId': ownerId});

      // グループのメンバー取得
      final mockMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockMemberDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockMemberQuery);
      when(mockMemberQuery.get()).thenAnswer((_) async => mockMemberSnapshot);
      when(mockMemberSnapshot.docs).thenReturn([mockMemberDoc]);
      when(mockMemberDoc.data()).thenReturn({'memberId': 'member1'});

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
      expect(result[0].groupId, 'group1');
      expect(result[0].groupName, '管理者グループ');
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
      final mockGroupMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockGroupMemberQuery);
      when(
        mockGroupMemberQuery.get(),
      ).thenAnswer((_) async => mockGroupMemberSnapshot);
      when(mockGroupMemberSnapshot.docs).thenReturn([]);

      // グループのメンバー取得（group1）
      final mockMemberQuery1 = MockQuery<Map<String, dynamic>>();
      final mockMemberQuery1OrderBy = MockQuery<Map<String, dynamic>>();
      final mockMemberSnapshot1 = MockQuerySnapshot<Map<String, dynamic>>();
      final mockMemberDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockMemberQuery1);
      when(
        mockMemberQuery1.orderBy('memberId', descending: false),
      ).thenReturn(mockMemberQuery1OrderBy);
      when(
        mockMemberQuery1OrderBy.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1);
      when(mockMemberSnapshot1.docs).thenReturn([mockMemberDoc1]);
      when(mockMemberDoc1.data()).thenReturn({'memberId': 'member1'});

      // グループのメンバー取得（group2）
      final mockMemberQuery2 = MockQuery<Map<String, dynamic>>();
      final mockMemberQuery2OrderBy = MockQuery<Map<String, dynamic>>();
      final mockMemberSnapshot2 = MockQuerySnapshot<Map<String, dynamic>>();
      final mockMemberDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group2'),
      ).thenReturn(mockMemberQuery2);
      when(
        mockMemberQuery2.orderBy('memberId', descending: false),
      ).thenReturn(mockMemberQuery2OrderBy);
      when(
        mockMemberQuery2OrderBy.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2);
      when(mockMemberSnapshot2.docs).thenReturn([mockMemberDoc2]);
      when(mockMemberDoc2.data()).thenReturn({'memberId': 'member2'});

      // メンバー詳細の取得
      when(
        mockFirestore.collection('members'),
      ).thenReturn(mockMembersCollection);

      final mockMemberDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot1Detail =
          MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member1')).thenReturn(mockMemberDocRef1);
      when(
        mockMemberDocRef1.get(),
      ).thenAnswer((_) async => mockMemberSnapshot1Detail);
      when(mockMemberSnapshot1Detail.exists).thenReturn(true);
      when(mockMemberSnapshot1Detail.id).thenReturn('member1');
      when(
        mockMemberSnapshot1Detail.data(),
      ).thenReturn({'displayName': 'Aメンバー'});

      final mockMemberDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockMemberSnapshot2Detail =
          MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockMembersCollection.doc('member2')).thenReturn(mockMemberDocRef2);
      when(
        mockMemberDocRef2.get(),
      ).thenAnswer((_) async => mockMemberSnapshot2Detail);
      when(mockMemberSnapshot2Detail.exists).thenReturn(true);
      when(mockMemberSnapshot2Detail.id).thenReturn('member2');
      when(
        mockMemberSnapshot2Detail.data(),
      ).thenReturn({'displayName': 'Bメンバー'});

      final result = await service.getGroupsWithMembersByMemberId(
        memberId,
        groupsOrderBy: [const OrderBy('name', descending: false)],
        membersOrderBy: [const OrderBy('memberId', descending: false)],
      );

      expect(result, hasLength(2));
      // メモリ内ソートでAグループ、Bグループの順になることを確認
      expect(result[0].groupId, 'group1');
      expect(result[0].groupName, 'Aグループ');
      expect(result[1].groupId, 'group2');
      expect(result[1].groupName, 'Bグループ');

      // membersOrderByで'memberId'の昇順でソートされることを確認
      verify(mockMemberQuery1.orderBy('memberId', descending: false)).called(1);
      verify(mockMemberQuery2.orderBy('memberId', descending: false)).called(1);
    });

    test('groupsOrderByとmembersOrderByを指定して管理グループとメンバーをソート順で取得する', () async {
      const ownerId = 'owner123';

      // 管理者として参加しているグループのモック設定
      when(mockFirestore.collection('groups')).thenReturn(mockGroupsCollection);

      when(
        mockGroupsCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);
      when(mockQueryDocumentSnapshot.id).thenReturn('group1');
      when(
        mockQueryDocumentSnapshot.data(),
      ).thenReturn({'name': '管理者グループ', 'ownerId': ownerId});

      // グループのメンバー取得
      final mockMemberQuery = MockQuery<Map<String, dynamic>>();
      final mockMemberQueryOrderBy = MockQuery<Map<String, dynamic>>();
      final mockMemberSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockMemberDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: 'group1'),
      ).thenReturn(mockMemberQuery);
      when(
        mockMemberQuery.orderBy('memberId', descending: true),
      ).thenReturn(mockMemberQueryOrderBy);
      when(
        mockMemberQueryOrderBy.get(),
      ).thenAnswer((_) async => mockMemberSnapshot);
      when(mockMemberSnapshot.docs).thenReturn([mockMemberDoc]);
      when(mockMemberDoc.data()).thenReturn({'memberId': 'member1'});

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
        membersOrderBy: [const OrderBy('memberId', descending: true)],
      );

      expect(result, hasLength(1));
      expect(result[0].groupId, 'group1');
      expect(result[0].groupName, '管理者グループ');
      expect(result[0].members, hasLength(1));
      expect(result[0].members[0].displayName, 'テストメンバー');

      // membersOrderByで'memberId'の降順でソートされることを確認
      verify(mockMemberQuery.orderBy('memberId', descending: true)).called(1);
    });
  });
}
