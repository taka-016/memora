import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/queries/group/firestore_group_event_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_group_event_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreGroupEventQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreGroupEventQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('group_events')).thenReturn(mockCollection);
      service = FirestoreGroupEventQueryService(firestore: mockFirestore);
    });

    test('groupIdで一覧を取得しorderByを適用できる', () async {
      const groupId = 'group001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(mockQuery.orderBy('year', descending: false)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('event001');
      when(
        mockDoc.data(),
      ).thenReturn({'groupId': groupId, 'year': 2025, 'memo': '運動会'});

      final result = await service.getGroupEventsByGroupId(
        groupId,
        orderBy: const [OrderBy('year', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<GroupEventDto>());
      expect(result.first.year, 2025);
      verify(mockQuery.orderBy('year', descending: false)).called(1);
    });

    test('例外時は空リストを返す', () async {
      when(
        mockCollection.where('groupId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getGroupEventsByGroupId('group001');

      expect(result, isEmpty);
    });
  });
}
