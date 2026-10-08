import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_repository.dart';
import 'package:memora/domain/entities/group/group.dart';

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

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
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
      verify(
        mockBatch.set(
          mockDocRef,
          argThat(
            allOf([
              containsPair('ownerId', 'admin001'),
              containsPair('name', 'テストグループ'),
              containsPair('memo', 'テストメモ'),
              contains('createdAt'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
      verify(mockBatch.commit()).called(1);
    });

    test('updateGroupがgroups collectionの該当ドキュメントを差分更新する', () async {
      final group = Group(id: 'group001', ownerId: 'admin001', name: '更新後グループ');
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();
      final mockGroupMembersCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockGroupMembersQuery = MockQuery<Map<String, dynamic>>();
      final mockGroupMembersSnapshot =
          MockQuerySnapshot<Map<String, dynamic>>();

      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockCollection.doc('group001')).thenReturn(mockDocRef);
      when(mockFirestore.collection('group_members'))
          .thenReturn(mockGroupMembersCollection);
      when(mockGroupMembersCollection.where('groupId', isEqualTo: 'group001'))
          .thenReturn(mockGroupMembersQuery);
      when(mockGroupMembersQuery.get())
          .thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([]);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.updateGroup(group);

      verify(
        mockBatch.update(
          mockDocRef,
          argThat(
            allOf([
              containsPair('ownerId', 'admin001'),
              containsPair('name', '更新後グループ'),
              contains('updatedAt'),
              predicate<Map<String, dynamic>>(
                (data) => !data.containsKey('createdAt'),
                'createdAtを含まない',
              ),
            ]),
          ),
        ),
      ).called(1);
      verify(mockBatch.commit()).called(1);
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
      when(mockFirestore.collection('group_members'))
          .thenReturn(mockGroupMembersCollection);
      when(mockGroupMembersCollection.where('groupId', isEqualTo: groupId))
          .thenReturn(mockGroupMembersQuery);
      when(mockGroupMembersQuery.get())
          .thenAnswer((_) async => mockGroupMembersSnapshot);
      when(mockGroupMembersSnapshot.docs).thenReturn([]);

      when(mockBatch.delete(any)).thenReturn(null);
      when(mockBatch.commit()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [firebaseFirestoreProvider.overrideWithValue(mockFirestore)],
      );
      addTearDown(container.dispose);
      repository =
          container.read(groupRepositoryProvider) as FirestoreGroupRepository;
      for (final collectionName in ['calendar_events', 'calendar_labels']) {
        final collection = MockCollectionReference<Map<String, dynamic>>();
        final query = MockQuery<Map<String, dynamic>>();
        final snapshot = MockQuerySnapshot<Map<String, dynamic>>();
        when(mockFirestore.collection(collectionName)).thenReturn(collection);
        when(collection.where('groupId', isEqualTo: groupId)).thenReturn(query);
        when(query.get()).thenAnswer((_) async => snapshot);
        when(snapshot.docs).thenReturn([]);
      }

      await repository.deleteGroup(groupId);
      verifyNever(mockDocRef.update(any));
      verify(mockFirestore.collection('calendar_events')).called(1);
      verify(mockFirestore.collection('calendar_labels')).called(1);

      verify(mockFirestore.batch()).called(1);
      verify(mockBatch.delete(mockDocRef)).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
