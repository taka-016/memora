import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_group_member_repository.dart';
import 'package:memora/domain/entities/group_member.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
])
import 'firestore_group_member_repository_test.mocks.dart';

void main() {
  group('FirestoreGroupMemberRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreGroupMemberRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('group_members')).thenReturn(mockCollection);
      repository = FirestoreGroupMemberRepository(firestore: mockFirestore);
    });

    test('saveGroupMemberがgroup_members collectionにグループメンバー情報をaddする', () async {
      final groupMember = GroupMember(
        id: 'groupmember001',
        groupId: 'group001',
        memberId: 'member001',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveGroupMember(groupMember);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('memberId', 'member001'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('getGroupMembersがFirestoreからGroupMemberのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('groupmember001');
      when(mockDoc1.data()).thenReturn({
        'groupId': 'group001',
        'memberId': 'member001',
      });

      final result = await repository.getGroupMembers();

      expect(result.length, 1);
      expect(result[0].id, 'groupmember001');
      expect(result[0].groupId, 'group001');
      expect(result[0].memberId, 'member001');
    });

    test('getGroupMembersがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getGroupMembers();

      expect(result, isEmpty);
    });

    test('deleteGroupMemberがgroup_members collectionの該当ドキュメントを削除する', () async {
      const groupMemberId = 'groupmember001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(groupMemberId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteGroupMember(groupMemberId);

      verify(mockCollection.doc(groupMemberId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('getGroupMembersByGroupIdが特定のグループのメンバーリストを返す', () async {
      const groupId = 'group001';

      when(mockCollection.where('groupId', isEqualTo: groupId)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('groupmember001');
      when(mockDoc1.data()).thenReturn({
        'groupId': groupId,
        'memberId': 'member001',
      });

      final result = await repository.getGroupMembersByGroupId(groupId);

      expect(result.length, 1);
      expect(result[0].id, 'groupmember001');
      expect(result[0].groupId, groupId);
      expect(result[0].memberId, 'member001');
    });
  });
}