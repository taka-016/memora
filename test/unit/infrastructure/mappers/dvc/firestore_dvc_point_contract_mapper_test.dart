import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/infrastructure/mappers/dvc/firestore_dvc_point_contract_mapper.dart';

void main() {
  group('FirestoreDvcPointContractMapper', () {
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

      final map = FirestoreDvcPointContractMapper.toFirestore(contract);

      expect(map['groupId'], 'group001');
      expect(map['contractName'], '契約A');
      expect(map['contractStartYearMonth'], isA<Timestamp>());
      expect(map['contractEndYearMonth'], isA<Timestamp>());
      expect(map['useYearStartMonth'], 10);
      expect(map['annualPoint'], 200);
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
