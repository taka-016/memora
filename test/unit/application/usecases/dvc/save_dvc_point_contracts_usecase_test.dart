import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_contracts_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';

void main() {
  group('SaveDvcPointContractsUsecase', () {
    test('既存契約を削除して契約一覧を保存できること', () async {
      final repository = _FakeDvcPointContractRepository();
      final usecase = SaveDvcPointContractsUsecase(repository);
      const groupId = 'group-1';
      final contracts = [
        DvcPointContractDto(
          id: '',
          groupId: groupId,
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2045, 9),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      ];

      await usecase.execute(groupId: groupId, contracts: contracts);

      expect(repository.deletedGroupIds, equals([groupId]));
      expect(repository.savedContracts, hasLength(1));
      expect(repository.savedContracts.first.contractName, equals('契約A'));
      expect(repository.savedContracts.first.groupId, equals(groupId));
    });
  });
}

class _FakeDvcPointContractRepository implements DvcPointContractRepository {
  final List<String> deletedGroupIds = [];
  final List<DvcPointContract> savedContracts = [];

  @override
  Future<void> deleteDvcPointContract(String contractId) async {}

  @override
  Future<void> deleteDvcPointContractsByGroupId(String groupId) async {
    deletedGroupIds.add(groupId);
  }

  @override
  Future<void> saveDvcPointContract(DvcPointContract contract) async {
    savedContracts.add(contract);
  }
}
