import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'dvc_point_contract_mapper_test.mocks.dart';

@GenerateMocks([DocumentSnapshot])
void main() {
  group('DvcPointContractMapper', () {
    test('FirestoreドキュメントからDtoへ変換できる', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('contract001');
      when(mockDoc.data()).thenReturn({
        'groupId': 'group001',
        'contractName': '契約A',
        'contractStartYearMonth': Timestamp.fromDate(DateTime(2024, 10)),
        'contractEndYearMonth': Timestamp.fromDate(DateTime(2042, 9)),
        'useYearStartMonth': 10,
        'annualPoint': 200,
      });

      final dto = DvcPointContractMapper.fromFirestore(mockDoc);

      expect(dto.id, 'contract001');
      expect(dto.groupId, 'group001');
      expect(dto.contractName, '契約A');
      expect(dto.contractStartYearMonth, DateTime(2024, 10));
      expect(dto.contractEndYearMonth, DateTime(2042, 9));
      expect(dto.useYearStartMonth, 10);
      expect(dto.annualPoint, 200);
    });

    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcPointContractDto(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      final entity = DvcPointContractMapper.toEntity(dto);

      expect(
        entity,
        DvcPointContract(
          id: 'contract001',
          groupId: 'group001',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2024, 10),
          contractEndYearMonth: DateTime(2042, 9),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      );
    });

    test('Firestoreの欠損値はデフォルトで補完される', () {
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('contract001');
      when(mockDoc.data()).thenReturn({});

      final dto = DvcPointContractMapper.fromFirestore(mockDoc);

      expect(dto.groupId, '');
      expect(dto.contractName, '');
      expect(
        dto.contractStartYearMonth,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
      expect(dto.contractEndYearMonth, DateTime.fromMillisecondsSinceEpoch(0));
      expect(dto.useYearStartMonth, 0);
      expect(dto.annualPoint, 0);
    });
  });
}
