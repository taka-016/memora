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
    test('削除対象を含む編集開始時の期待値を保存要求へ渡す', () async {
      final repository = MockDvcPointContractRepository();
      when(repository.saveDvcPointContracts('group', [], expectedVersions: {'deleted': 7})).thenAnswer((_) async {});
      await SaveDvcPointContractsUsecase(repository).execute(groupId: 'group', contracts: [], expectedVersions: {'deleted': 7});
      verify(repository.saveDvcPointContracts('group', [], expectedVersions: {'deleted': 7})).called(1);
    });

    test('既存IDを維持して契約一覧を一括保存する', () async {
      final repository = MockDvcPointContractRepository();
      final usecase = SaveDvcPointContractsUsecase(repository);
      const groupId = 'group-1';
      final contracts = [
        DvcPointContractDto(
          id: 'c1',
          groupId: groupId,
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2045, 9),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      ];
      when(repository.saveDvcPointContracts(groupId, any))
          .thenAnswer((_) async {});

      await usecase.execute(groupId: groupId, contracts: contracts);

      verifyNever(repository.deleteDvcPointContractsByGroupId(any));
      final verification = verify(
        repository.saveDvcPointContracts(groupId, captureAny),
      )..called(1);
      final saved = verification.captured.single as List<DvcPointContract>;
      expect(saved.single.id, 'c1');
      expect(saved.single.contractName, '契約A');
    });
  });
}
