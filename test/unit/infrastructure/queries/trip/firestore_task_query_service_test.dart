import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/queries/trip/firestore_task_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_task_query_service_test.mocks.dart';

@GenerateMocks([
  DocumentReference,
  DocumentSnapshot,
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreTaskQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockTasksCollection;
    late FirestoreTaskQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockTasksCollection = MockCollectionReference<Map<String, dynamic>>();
      when(mockFirestore.collection('tasks')).thenReturn(mockTasksCollection);
      final parents = MockCollectionReference<Map<String, dynamic>>();
      final parentRef = MockDocumentReference<Map<String, dynamic>>();
      final parent = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockFirestore.collection('trip_entries')).thenReturn(parents);
      when(parents.doc(any)).thenReturn(parentRef);
      when(parentRef.get()).thenAnswer((_) async => parent);
      when(parent.exists).thenReturn(true);
      when(parent.data()).thenReturn({'groupId': 'g'});
      service = FirestoreTaskQueryService(firestore: mockFirestore);
    });

    test('旅行IDでタスク一覧を取得しorderByを適用できる', () async {
      const tripId = 'trip001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockQuery.where('groupId', isEqualTo: anyNamed('isEqualTo'))).thenReturn(mockQuery);
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(mockTasksCollection.where('tripId', isEqualTo: tripId))
          .thenReturn(mockQuery);
      when(mockQuery.orderBy('orderIndex', descending: false))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('task001');
      when(mockDoc.data()).thenReturn({
        'tripId': tripId,
        'orderIndex': 0,
        'name': '準備',
        'isCompleted': false,
      });

      final result = await service.getTasksByTripId(
        tripId,
        orderBy: const [OrderBy('orderIndex', descending: false)],
      );
      verify(mockQuery.where('groupId', isEqualTo: 'g')).called(1);

      expect(result, hasLength(1));
      expect(result.first, isA<TaskDto>());
      expect(result.first.id, 'task001');
      verify(mockQuery.orderBy('orderIndex', descending: false)).called(1);
    });

    test('取得時に例外が発生した場合は取得失敗を伝える', () async {
      when(
        mockTasksCollection.where('tripId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore error'));

      await expectLater(
        service.getTasksByTripId('trip001'),
        throwsA(isA<TestException>()),
      );
    });
  });
}
