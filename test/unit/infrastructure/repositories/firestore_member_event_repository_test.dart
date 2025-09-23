import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_member_event_repository.dart';
import 'package:memora/domain/entities/member_event.dart';
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
import 'firestore_member_event_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberEventRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberEventRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockFirestore.collection('member_events'),
      ).thenReturn(mockCollection);
      repository = FirestoreMemberEventRepository(firestore: mockFirestore);
    });

    test('saveMemberEventがmember_events collectionにメンバーイベント情報をaddする', () async {
      final memberEvent = MemberEvent(
        id: 'memberevent001',
        memberId: 'member001',
        type: 'birthday',
        name: 'テストイベント',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 2),
        memo: 'テストメモ',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveMemberEvent(memberEvent);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('memberId', 'member001'),
              containsPair('type', 'birthday'),
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

    test('getMemberEventsがFirestoreからMemberEventのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('memberevent001');
      when(mockDoc1.data()).thenReturn({
        'memberId': 'member001',
        'type': 'birthday',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final result = await repository.getMemberEvents();

      expect(result.length, 1);
      expect(result[0].id, 'memberevent001');
      expect(result[0].memberId, 'member001');
      expect(result[0].type, 'birthday');
      expect(result[0].name, 'テストイベント');
      expect(result[0].memo, 'テストメモ');
    });

    test('getMemberEventsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(TestException('Firestore error'));

      final result = await repository.getMemberEvents();

      expect(result, isEmpty);
    });

    test('deleteMemberEventがmember_events collectionの該当ドキュメントを削除する', () async {
      const memberEventId = 'memberevent001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(memberEventId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteMemberEvent(memberEventId);

      verify(mockCollection.doc(memberEventId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('getMemberEventsByMemberIdが特定のメンバーのイベントリストを返す', () async {
      const memberId = 'member001';

      when(
        mockCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('memberevent001');
      when(mockDoc1.data()).thenReturn({
        'memberId': memberId,
        'type': 'birthday',
        'name': 'テストイベント',
        'startDate': Timestamp.fromDate(DateTime(2025, 6, 1)),
        'endDate': Timestamp.fromDate(DateTime(2025, 6, 2)),
        'memo': 'テストメモ',
      });

      final result = await repository.getMemberEventsByMemberId(memberId);

      expect(result.length, 1);
      expect(result[0].id, 'memberevent001');
      expect(result[0].memberId, memberId);
    });

    test('deleteMemberEventsByMemberIdが指定したmemberIdの全イベントを削除する', () async {
      const memberId = 'member001';
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockWriteBatch = MockWriteBatch();

      when(
        mockCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
      when(mockDoc1.reference).thenReturn(mockDocRef1);
      when(mockDoc2.reference).thenReturn(mockDocRef2);
      when(mockFirestore.batch()).thenReturn(mockWriteBatch);
      when(mockWriteBatch.commit()).thenAnswer((_) async {});

      await repository.deleteMemberEventsByMemberId(memberId);

      verify(mockFirestore.batch()).called(1);
      verify(mockWriteBatch.delete(mockDocRef1)).called(1);
      verify(mockWriteBatch.delete(mockDocRef2)).called(1);
      verify(mockWriteBatch.commit()).called(1);
    });
  });
}
