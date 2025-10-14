import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_group_repository.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/value_objects/order_by.dart';
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

    test('getGroupsがorderByパラメータでソートする', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockCollection.orderBy('name', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({'name': 'テストグループ', 'memo': 'テストメモ'});

      final result = await repository.getGroups(
        orderBy: [const OrderBy('name')],
      );

      expect(result.length, 1);
      expect(result[0].name, 'テストグループ');
      verify(mockCollection.orderBy('name', descending: false)).called(1);
    });

    test('getGroupByIdがorderByパラメータでメンバーをソートする', () async {
      const groupId = 'group001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery1 = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersQuery2 = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(mockCollection.doc(groupId)).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot.id).thenReturn(groupId);
      when(
        mockDocSnapshot.data(),
      ).thenReturn({'ownerId': 'owner-id', 'name': 'テストグループ'});

      when(
        mockFirestore.collection('group_members'),
      ).thenReturn(mockGroupMembersCollection);
      when(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockGroupMembersQuery1);
      when(
        mockGroupMembersQuery1.orderBy('memberId', descending: false),
      ).thenReturn(mockGroupMembersQuery2);
      when(
        mockGroupMembersQuery2.get(),
      ).thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([]);

      await repository.getGroupById(
        groupId,
        orderBy: [const OrderBy('memberId')],
      );

      verify(
        mockGroupMembersCollection.where('groupId', isEqualTo: groupId),
      ).called(1);
      verify(
        mockGroupMembersQuery1.orderBy('memberId', descending: false),
      ).called(1);
    });

    test('getGroupsByOwnerIdがorderByパラメータでソートする', () async {
      const ownerId = 'owner001';
      final mockQuery1 = MockQuery<Map<String, dynamic>>();
      final mockQuery2 = MockQuery<Map<String, dynamic>>();
      final mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('ownerId', isEqualTo: ownerId),
      ).thenReturn(mockQuery1);
      when(
        mockQuery1.orderBy('name', descending: false),
      ).thenReturn(mockQuery2);
      when(mockQuery2.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('group001');
      when(mockDoc1.data()).thenReturn({'ownerId': ownerId, 'name': 'テストグループ'});

      final result = await repository.getGroupsByOwnerId(
        ownerId,
        orderBy: [const OrderBy('name')],
      );

      expect(result.length, 1);
      expect(result[0].name, 'テストグループ');
      verify(mockCollection.where('ownerId', isEqualTo: ownerId)).called(1);
      verify(mockQuery1.orderBy('name', descending: false)).called(1);
    });
  });
}
