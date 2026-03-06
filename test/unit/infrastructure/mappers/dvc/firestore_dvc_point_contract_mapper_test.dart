import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_contract_mapper.dart';

import '../../../../helpers/fake_document_snapshot.dart';

void main() {
  group('FirestoreDvcPointContractMapper', () {
    test('FirestoreドキュメントからDtoへ変換できる', () {
      final doc = FakeDocumentSnapshot(
        docId: 'contract001',
        data: {
          'groupId': 'group001',
          'contractName': '契約A',
          'contractStartYearMonth': Timestamp.fromDate(DateTime(2024, 10)),
          'contractEndYearMonth': Timestamp.fromDate(DateTime(2042, 9)),
          'useYearStartMonth': 10,
          'annualPoint': 200,
        },
      );

      final dto = FirestoreDvcPointContractMapper.fromFirestore(doc);

      expect(dto.id, 'contract001');
      expect(dto.groupId, 'group001');
      expect(dto.contractName, '契約A');
      expect(dto.useYearStartMonth, 10);
      expect(dto.annualPoint, 200);
    });

    test('Firestore欠損値はデフォルトで補完する', () {
      final doc = FakeDocumentSnapshot(docId: 'contract002', data: {});

      final dto = FirestoreDvcPointContractMapper.fromFirestore(doc);

      expect(dto.id, 'contract002');
      expect(dto.groupId, '');
      expect(dto.contractName, '');
      expect(dto.useYearStartMonth, 0);
      expect(dto.annualPoint, 0);
    });

    test('エンティティをFirestoreマップへ変換できる', () {
      final contract = DvcPointContract(
        id: 'contract003',
        groupId: 'group003',
        contractName: '契約B',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      final map = FirestoreDvcPointContractMapper.toFirestore(contract);

      expect(map['groupId'], 'group003');
      expect(map['contractName'], '契約B');
      expect(map['contractStartYearMonth'], isA<Timestamp>());
      expect(map['contractEndYearMonth'], isA<Timestamp>());
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
