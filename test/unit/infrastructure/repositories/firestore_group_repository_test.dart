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

    test('saveGroupがgroups collectionにグループ情報をaddする', () async {
      final group = Group(
        id: 'group001',
        administratorId: 'admin001',
        name: 'テストグループ',
        memo: 'テストメモ',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveGroup(group);

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
  });
}
