import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_point_usage_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_dvc_point_usage_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreDvcPointUsageQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreDvcPointUsageQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('dvc_point_usages'),
      ).thenReturn(mockCollection);
      service = FirestoreDvcPointUsageQueryService(firestore: mockFirestore);
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
        mockQuery.orderBy('usageYearMonth', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('usage001');
      when(mockDoc.data()).thenReturn({
        'groupId': groupId,
        'usageYearMonth': Timestamp.fromDate(DateTime(2025, 10)),
        'usedPoint': 60,
        'memo': 'ホテル',
      });

      final result = await service.getDvcPointUsagesByGroupId(
        groupId,
        orderBy: const [OrderBy('usageYearMonth', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<DvcPointUsageDto>());
      expect(result.first.usedPoint, 60);
      verify(mockQuery.orderBy('usageYearMonth', descending: false)).called(1);
    });

    test('例外時は空リストを返す', () async {
      when(
        mockCollection.where('groupId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getDvcPointUsagesByGroupId('group001');

      expect(result, isEmpty);
    });
  });
}
