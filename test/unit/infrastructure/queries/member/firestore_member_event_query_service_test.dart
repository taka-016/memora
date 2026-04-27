import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/queries/member/firestore_member_event_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_member_event_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreMemberEventQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreMemberEventQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('member_events'),
      ).thenReturn(mockCollection);
      service = FirestoreMemberEventQueryService(firestore: mockFirestore);
    });

    test('memberId一覧で年表表示用のメンバーイベントを取得しorderByを適用できる', () async {
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockOrderedQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where(
          'memberId',
          whereIn: argThat(
            equals(['member001', 'member002']),
            named: 'whereIn',
          ),
        ),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('year', descending: false),
      ).thenReturn(mockOrderedQuery);
      when(mockOrderedQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('event001');
      when(
        mockDoc.data(),
      ).thenReturn({'memberId': 'member001', 'year': 2026, 'memo': '入学式'});

      final result = await service.getMemberEventsByMemberIds(
        const ['member001', 'member002'],
        orderBy: const [OrderBy('year', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<MemberEventDto>());
      expect(result.first.year, 2026);
      verify(mockQuery.orderBy('year', descending: false)).called(1);
    });

    test('複数チャンクで取得した結果もorderByに合わせて全体を並び替える', () async {
      final memberIds = [
        for (var index = 1; index <= 31; index++)
          'member${index.toString().padLeft(3, '0')}',
      ];
      final firstQuery = MockQuery<Map<String, dynamic>>();
      final secondQuery = MockQuery<Map<String, dynamic>>();
      final firstOrderedQuery = MockQuery<Map<String, dynamic>>();
      final secondOrderedQuery = MockQuery<Map<String, dynamic>>();
      final firstSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final secondSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final firstDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final secondDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where(
          'memberId',
          whereIn: argThat(
            equals(memberIds.take(30).toList()),
            named: 'whereIn',
          ),
        ),
      ).thenReturn(firstQuery);
      when(
        mockCollection.where(
          'memberId',
          whereIn: argThat(
            equals(memberIds.skip(30).toList()),
            named: 'whereIn',
          ),
        ),
      ).thenReturn(secondQuery);
      when(
        firstQuery.orderBy('year', descending: false),
      ).thenReturn(firstOrderedQuery);
      when(
        secondQuery.orderBy('year', descending: false),
      ).thenReturn(secondOrderedQuery);
      when(firstOrderedQuery.get()).thenAnswer((_) async => firstSnapshot);
      when(secondOrderedQuery.get()).thenAnswer((_) async => secondSnapshot);
      when(firstSnapshot.docs).thenReturn([firstDoc]);
      when(secondSnapshot.docs).thenReturn([secondDoc]);
      when(firstDoc.id).thenReturn('event-2027');
      when(
        firstDoc.data(),
      ).thenReturn({'memberId': 'member001', 'year': 2027, 'memo': '卒業式'});
      when(secondDoc.id).thenReturn('event-2026');
      when(
        secondDoc.data(),
      ).thenReturn({'memberId': 'member031', 'year': 2026, 'memo': '入学式'});

      final result = await service.getMemberEventsByMemberIds(
        memberIds,
        orderBy: const [OrderBy('year', descending: false)],
      );

      expect(result.map((event) => event.year), [2026, 2027]);
    });

    test('memberId一覧が空ならFirestoreへ問い合わせず空リストを返す', () async {
      final result = await service.getMemberEventsByMemberIds(const []);

      expect(result, isEmpty);
      verifyNever(
        mockCollection.where('memberId', whereIn: anyNamed('whereIn')),
      );
    });

    test('例外時は空リストを返す', () async {
      when(
        mockCollection.where(
          'memberId',
          whereIn: argThat(equals(['member001']), named: 'whereIn'),
        ),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getMemberEventsByMemberIds(const [
        'member001',
      ]);

      expect(result, isEmpty);
    });
  });
}
