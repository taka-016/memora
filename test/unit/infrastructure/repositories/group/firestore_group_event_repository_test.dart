import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/infrastructure/repositories/group/firestore_group_event_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  WriteBatch,
])
import 'firestore_group_event_repository_test.mocks.dart';

void main() {
  group('FirestoreGroupEventRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreGroupEventRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('group_events')).thenReturn(mockCollection);
      repository = FirestoreGroupEventRepository(firestore: mockFirestore);
    });

    test('idが空の場合はgroup_events collectionにaddする', () async {
      const groupEvent = GroupEvent(
        id: '',
        groupId: 'group001',
        year: 2025,
        memo: 'テストメモ',
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.add(any)).thenAnswer((_) async => mockDocRef);
      when(mockDocRef.id).thenReturn('saved-event-id');

      await repository.saveGroupEvent(groupEvent);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('year', 2025),
              containsPair('memo', 'テストメモ'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('idがある場合は該当ドキュメントをsetする', () async {
      const groupEvent = GroupEvent(
        id: 'groupevent001',
        groupId: 'group001',
        year: 2025,
        memo: '更新後メモ',
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(groupEvent.id)).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      await repository.saveGroupEvent(groupEvent);

      verify(mockCollection.doc(groupEvent.id)).called(1);
      verify(
        mockDocRef.set(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('year', 2025),
              containsPair('memo', '更新後メモ'),
              contains('updatedAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('deleteGroupEventがgroup_events collectionの該当ドキュメントを削除する', () async {
      const groupEventId = 'groupevent001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(groupEventId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteGroupEvent(groupEventId);

      verify(mockCollection.doc(groupEventId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('deleteGroupEventsByGroupIdが指定したgroupIdの全イベントを削除する', () async {
      const groupId = 'group001';
      final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockBatch = MockWriteBatch();

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.reference).thenReturn(mockDocRef1);
      when(mockDoc2.reference).thenReturn(mockDocRef2);
      when(mockFirestore.batch()).thenReturn(mockBatch);
      when(mockBatch.commit()).thenAnswer((_) async {});

      await repository.deleteGroupEventsByGroupId(groupId);

      verify(mockCollection.where('groupId', isEqualTo: groupId)).called(1);
      verify(mockQuery.get()).called(1);
      verify(mockFirestore.batch()).called(1);
      verify(mockBatch.delete(mockDocRef1)).called(1);
      verify(mockBatch.delete(mockDocRef2)).called(1);
      verify(mockBatch.commit()).called(1);
    });
  });
}
