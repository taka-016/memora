import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_group_event_repository.dart';
import 'package:memora/domain/entities/group_event.dart';
import '../../../helpers/test_exception.dart';

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

    test('saveGroupEventがgroup_events collectionにグループイベント情報をaddする', () async {
      final groupEvent = GroupEvent(
        id: 'groupevent001',
        groupId: 'group001',
        type: 'meeting',
        name: 'テストイベント',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 2),
        memo: 'テストメモ',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveGroupEvent(groupEvent);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('groupId', 'group001'),
              containsPair('type', 'meeting'),
              containsPair('name', 'テストイベント'),
              containsPair('memo', 'テストメモ'),
              contains('startDate'),
              contains('endDate'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('getGroupEventsがFirestoreからGroupEventのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('groupevent001');
      when(mockDoc1.data()).thenReturn({
        'groupId': 'group001',
        'type': 'meeting',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final result = await repository.getGroupEvents();

      expect(result.length, 1);
      expect(result[0].id, 'groupevent001');
      expect(result[0].groupId, 'group001');
      expect(result[0].type, 'meeting');
      expect(result[0].name, 'テストイベント');
      expect(result[0].memo, 'テストメモ');
    });

    test('getGroupEventsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(TestException('Firestore error'));

      final result = await repository.getGroupEvents();

      expect(result, isEmpty);
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

    test('getGroupEventsByGroupIdが特定のグループのイベントリストを返す', () async {
      const groupId = 'group001';

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('groupevent001');
      when(mockDoc1.data()).thenReturn({
        'groupId': groupId,
        'type': 'meeting',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final result = await repository.getGroupEventsByGroupId(groupId);

      expect(result.length, 1);
      expect(result[0].id, 'groupevent001');
      expect(result[0].groupId, groupId);
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
