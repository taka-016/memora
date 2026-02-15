import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/queries/dvc/firestore_dvc_point_contract_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_dvc_point_contract_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreDvcPointContractQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreDvcPointContractQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('dvc_point_contracts'),
      ).thenReturn(mockCollection);
      service = FirestoreDvcPointContractQueryService(firestore: mockFirestore);
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
        mockQuery.orderBy('contractStartYearMonth', descending: false),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('contract001');
      when(mockDoc.data()).thenReturn({
        'groupId': groupId,
        'contractName': '契約A',
        'contractStartYearMonth': Timestamp.fromDate(DateTime(2024, 10)),
        'contractEndYearMonth': Timestamp.fromDate(DateTime(2042, 9)),
        'useYearStartMonth': 10,
        'annualPoint': 200,
      });

      final result = await service.getDvcPointContractsByGroupId(
        groupId,
        orderBy: const [OrderBy('contractStartYearMonth', descending: false)],
      );

      expect(result, hasLength(1));
      expect(result.first, isA<DvcPointContractDto>());
      expect(result.first.contractName, '契約A');
      verify(
        mockQuery.orderBy('contractStartYearMonth', descending: false),
      ).called(1);
    });

    test('例外時は空リストを返す', () async {
      when(
        mockCollection.where('groupId', isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('firestore error'));

      final result = await service.getDvcPointContractsByGroupId('group001');

      expect(result, isEmpty);
    });
  });
}
