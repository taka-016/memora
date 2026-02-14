import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';

void main() {
  group('DvcPointContractDto', () {
    test('必須パラメータで生成できる', () {
      final dto = DvcPointContractDto(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      expect(dto.id, 'contract001');
      expect(dto.groupId, 'group001');
      expect(dto.contractName, '契約A');
      expect(dto.contractStartYearMonth, DateTime(2024, 10));
      expect(dto.contractEndYearMonth, DateTime(2042, 9));
      expect(dto.useYearStartMonth, 10);
      expect(dto.annualPoint, 200);
    });

    test('copyWithで値を更新できる', () {
      final dto = DvcPointContractDto(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      final copied = dto.copyWith(contractName: '契約B', annualPoint: 250);

      expect(copied.contractName, '契約B');
      expect(copied.annualPoint, 250);
      expect(copied.groupId, 'group001');
    });
  });
}
