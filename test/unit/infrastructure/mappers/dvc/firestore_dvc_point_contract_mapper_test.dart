import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_contract_mapper.dart';

import 'firestore_dvc_point_contract_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('FirestoreDvcPointContractMapper', () {
    test('FirestoreドキュメントからDvcPointContractDtoへ変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('contract001');
      when(doc.data()).thenReturn({
        'groupId': 'group001',
        'contractName': '契約A',
        'contractStartYearMonth': Timestamp.fromDate(DateTime(2024, 10)),
        'contractEndYearMonth': Timestamp.fromDate(DateTime(2042, 9)),
        'useYearStartMonth': 10.9,
        'annualPoint': 200,
      });

      final result = FirestoreDvcPointContractMapper.fromFirestore(doc);

      expect(result.id, 'contract001');
      expect(result.groupId, 'group001');
      expect(result.contractName, '契約A');
      expect(result.contractStartYearMonth, DateTime(2024, 10));
      expect(result.contractEndYearMonth, DateTime(2042, 9));
      expect(result.useYearStartMonth, 10);
      expect(result.annualPoint, 200);
    });

    test('Firestoreの欠損値をデフォルトで変換できる', () {
      final doc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(doc.id).thenReturn('contract002');
      when(doc.data()).thenReturn({});

      final result = FirestoreDvcPointContractMapper.fromFirestore(doc);

      expect(result.id, 'contract002');
      expect(result.groupId, '');
      expect(result.contractName, '');
      expect(
        result.contractStartYearMonth,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(
        result.contractEndYearMonth,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(result.useYearStartMonth, 0);
      expect(result.annualPoint, 0);
    });

    test('エンティティをFirestoreマップへ変換できる', () {
      final contract = DvcPointContract(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      final map = FirestoreDvcPointContractMapper.toCreateFirestore(contract);

      expect(map['groupId'], 'group001');
      expect(map['contractName'], '契約A');
      expect(map['contractStartYearMonth'], isA<Timestamp>());
      expect(map['contractEndYearMonth'], isA<Timestamp>());
      expect(map['useYearStartMonth'], 10);
      expect(map['annualPoint'], 200);
      expect(map['createdAt'], isA<FieldValue>());
      expect(map['updatedAt'], isA<FieldValue>());
    });
  });
}
