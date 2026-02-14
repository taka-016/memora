import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

void main() {
  group('DvcPointContract', () {
    test('必須パラメータでインスタンス化できる', () {
      final contract = DvcPointContract(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      expect(contract.id, 'contract001');
      expect(contract.groupId, 'group001');
      expect(contract.contractName, '契約A');
      expect(contract.contractStartYearMonth, DateTime(2024, 10));
      expect(contract.contractEndYearMonth, DateTime(2042, 9));
      expect(contract.useYearStartMonth, 10);
      expect(contract.annualPoint, 200);
    });

    test('copyWithで値を更新できる', () {
      final contract = DvcPointContract(
        id: 'contract001',
        groupId: 'group001',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      final copied = contract.copyWith(contractName: '契約B', annualPoint: 250);

      expect(copied.contractName, '契約B');
      expect(copied.annualPoint, 250);
      expect(copied.groupId, 'group001');
    });
  });
}
