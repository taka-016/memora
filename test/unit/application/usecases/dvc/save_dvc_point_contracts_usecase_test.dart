import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_contracts_usecase.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'save_dvc_point_contracts_usecase_test.mocks.dart';

@GenerateMocks([DvcPointContractRepository])
void main() {
  group('SaveDvcPointContractsUsecase', () {
    test('既存契約を削除して契約一覧を保存できること', () async {
      final repository = MockDvcPointContractRepository();
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
      when(
        repository.deleteDvcPointContractsByGroupId(groupId),
      ).thenAnswer((_) async {});
      when(repository.saveDvcPointContract(any)).thenAnswer((_) async {});

      await usecase.execute(groupId: groupId, contracts: contracts);

      verify(repository.deleteDvcPointContractsByGroupId(groupId)).called(1);
      final verification = verify(repository.saveDvcPointContract(captureAny))
        ..called(1);
      final savedContract = verification.captured.single as DvcPointContract;
      expect(savedContract.contractName, equals('契約A'));
      expect(savedContract.groupId, equals(groupId));
    });
  });
}
