import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/infrastructure/repositories/member/firestore_member_event_repository.dart';
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
import 'firestore_member_event_repository_test.mocks.dart';

void main() {
  group('FirestoreMemberEventRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberEventRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQuery<Map<String, dynamic>> mockMemberQuery;
    late MockQuery<Map<String, dynamic>> mockMemberYearQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockMemberQuery = MockQuery<Map<String, dynamic>>();
      mockMemberYearQuery = MockQuery<Map<String, dynamic>>();
      when(
        mockFirestore.collection('member_events'),
      ).thenReturn(mockCollection);
      repository = FirestoreMemberEventRepository(firestore: mockFirestore);
    });

    void stubFindByMemberIdAndYear(String memberId, int year) {
      when(
        mockCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockMemberQuery);
      when(
        mockMemberQuery.where('year', isEqualTo: year),
      ).thenReturn(mockMemberYearQuery);
    }

    test('saveMemberEventは同一memberId・yearの正規ドキュメントを更新する', () async {
      const memberEvent = MemberEvent(
        id: '',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      stubFindByMemberIdAndYear(memberEvent.memberId, memberEvent.year);
      when(mockCollection.doc('member001_2026')).thenReturn(mockDocRef);
      when(
        mockMemberYearQuery.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('member001_2026');
      when(mockDocRef.set(any, any)).thenAnswer((_) async {});

      final savedId = await repository.saveMemberEvent(memberEvent);

      expect(savedId, 'member001_2026');
      verify(
        mockDocRef.set(
          argThat(
            allOf([
              containsPair('memberId', 'member001'),
              containsPair('year', 2026),
              containsPair('memo', '入学式'),
              contains('updatedAt'),
              isNot(contains('createdAt')),
            ]),
          ),
          any,
        ),
      ).called(1);
      verifyNever(mockCollection.add(any));
    });

    test('saveMemberEventは既存イベントがなくメモがある場合に正規ドキュメントを作成する', () async {
      const memberEvent = MemberEvent(
        id: '',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      stubFindByMemberIdAndYear(memberEvent.memberId, memberEvent.year);
      when(mockCollection.doc('member001_2026')).thenReturn(mockDocRef);
      when(
        mockMemberYearQuery.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockDocRef.set(any, any)).thenAnswer((_) async {});

      final savedId = await repository.saveMemberEvent(memberEvent);

      expect(savedId, 'member001_2026');
      verify(
        mockDocRef.set(
          argThat(
            allOf([
              containsPair('memberId', 'member001'),
              containsPair('year', 2026),
              containsPair('memo', '入学式'),
              contains('createdAt'),
            ]),
          ),
          any,
        ),
      ).called(1);
      verifyNever(mockCollection.add(any));
    });

    test('saveMemberEventは同一memberId・yearの重複ドキュメントを削除する', () async {
      const memberEvent = MemberEvent(
        id: '',
        memberId: 'member001',
        year: 2026,
        memo: '入学式',
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockDuplicateDoc =
          MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDuplicateDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockWriteBatch = MockWriteBatch();

      stubFindByMemberIdAndYear(memberEvent.memberId, memberEvent.year);
      when(mockCollection.doc('member001_2026')).thenReturn(mockDocRef);
      when(
        mockMemberYearQuery.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDuplicateDoc]);
      when(mockDuplicateDoc.id).thenReturn('legacy-event-id');
      when(mockDuplicateDoc.reference).thenReturn(mockDuplicateDocRef);
      when(mockDocRef.set(any, any)).thenAnswer((_) async {});
      when(mockFirestore.batch()).thenReturn(mockWriteBatch);
      when(mockWriteBatch.commit()).thenAnswer((_) async {});

      final savedId = await repository.saveMemberEvent(memberEvent);

      expect(savedId, 'member001_2026');
      verify(mockDocRef.set(any, any)).called(1);
      verify(mockFirestore.batch()).called(1);
      verify(mockWriteBatch.delete(mockDuplicateDocRef)).called(1);
      verify(mockWriteBatch.commit()).called(1);
    });

    test('saveMemberEventは既存イベントがありメモが空の場合に削除する', () async {
      const memberEvent = MemberEvent(
        id: '',
        memberId: 'member001',
        year: 2026,
        memo: '',
      );
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockWriteBatch = MockWriteBatch();

      stubFindByMemberIdAndYear(memberEvent.memberId, memberEvent.year);
      when(mockCollection.doc('member001_2026')).thenReturn(mockDocRef);
      when(
        mockMemberYearQuery.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('member001_2026');
      when(mockDoc.reference).thenReturn(mockDocRef);
      when(mockFirestore.batch()).thenReturn(mockWriteBatch);
      when(mockWriteBatch.commit()).thenAnswer((_) async {});

      final savedId = await repository.saveMemberEvent(memberEvent);

      expect(savedId, '');
      verify(mockWriteBatch.delete(mockDocRef)).called(1);
      verify(mockWriteBatch.commit()).called(1);
      verifyNever(mockDocRef.set(any, any));
      verifyNever(mockCollection.add(any));
    });

    test('saveMemberEventは既存イベントがなくメモが空の場合に新規作成しない', () async {
      const memberEvent = MemberEvent(
        id: '',
        memberId: 'member001',
        year: 2026,
        memo: '',
      );
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      final mockWriteBatch = MockWriteBatch();

      stubFindByMemberIdAndYear(memberEvent.memberId, memberEvent.year);
      when(mockCollection.doc('member001_2026')).thenReturn(mockDocRef);
      when(
        mockMemberYearQuery.get(),
      ).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);
      when(mockFirestore.batch()).thenReturn(mockWriteBatch);
      when(mockWriteBatch.commit()).thenAnswer((_) async {});

      final savedId = await repository.saveMemberEvent(memberEvent);

      expect(savedId, '');
      verify(mockWriteBatch.delete(mockDocRef)).called(1);
      verify(mockWriteBatch.commit()).called(1);
      verifyNever(mockCollection.add(any));
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

    test('deleteMemberEventsByMemberIdが指定したmemberIdの全イベントを削除する', () async {
      const memberId = 'member001';
      final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final mockDocRef1 = MockDocumentReference<Map<String, dynamic>>();
      final mockDocRef2 = MockDocumentReference<Map<String, dynamic>>();
      final mockWriteBatch = MockWriteBatch();

      when(
        mockCollection.where('memberId', isEqualTo: memberId),
      ).thenReturn(mockMemberQuery);
      when(mockMemberQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
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
