import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_limited_point_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_dvc_limited_point_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreDvcLimitedPointQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreDvcLimitedPointQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('dvc_limited_points'),
      ).thenReturn(mockCollection);
      service = FirestoreDvcLimitedPointQueryService(firestore: mockFirestore);
    });

    test('groupIdで一覧を取得しorderByを適用できる', () async {
      const groupId = 'group001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockCollection.where('groupId', isEqualTo: groupId),
      ).thenReturn(mockQuery);
      when(
        mockQuery.orderBy('startYearMonth', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('limited001');
      when(mockDoc.data()).thenReturn({
        'groupId': groupId,
        'startYearMonth': Timestamp.fromDate(DateTime(2025, 7)),
        'endYearMonth': Timestamp.fromDate(DateTime(2025, 12)),
        'point': 30,
        'memo': '追加分',
      });

      final result = await service.getDvcLimitedPointsByGroupId(
        groupId,
        orderBy: const [OrderBy('startYearMonth', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<DvcLimitedPointDto>());
      expect(result.first.point, 30);
      verify(mockQuery.orderBy('startYearMonth', descending: false)).called(1);
    });

    test('例外時は空リストを返す', () async {
      when(
        mockCollection.where('groupId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getDvcLimitedPointsByGroupId('group001');

      expect(result, isEmpty);
    });
  });
}
