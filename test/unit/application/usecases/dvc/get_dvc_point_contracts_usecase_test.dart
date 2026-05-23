import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_dvc_point_contracts_usecase_test.mocks.dart';

@GenerateMocks([DvcPointContractQueryService])
void main() {
  group('GetDvcPointContractsUsecase', () {
    test('グループIDで契約一覧を取得できること', () async {
      const groupId = 'group-1';
      final expectedContracts = [
        DvcPointContractDto(
          id: 'contract-1',
          groupId: groupId,
          contractName: '契約A',
          contractStartYearMonth: DateTime(2025, 10),
          contractEndYearMonth: DateTime(2045, 9),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      ];
      final queryService = MockDvcPointContractQueryService();
      final usecase = GetDvcPointContractsUsecase(queryService);
      when(
        queryService.getDvcPointContractsByGroupId(
          groupId,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => expectedContracts);

      final result = await usecase.execute(groupId);

      expect(result, equals(expectedContracts));
      final verification = verify(
        queryService.getDvcPointContractsByGroupId(
          groupId,
          orderBy: captureAnyNamed('orderBy'),
        ),
      )..called(1);
      expect(
        verification.captured.single,
        equals([const OrderBy('contractName', descending: false)]),
      );
    });
  });
}
