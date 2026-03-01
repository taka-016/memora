import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';
import 'package:memora/domain/value_objects/order_by.dart';

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
      final queryService = _FakeDvcPointContractQueryService(expectedContracts);
      final usecase = GetDvcPointContractsUsecase(queryService);

      final result = await usecase.execute(groupId);

      expect(result, equals(expectedContracts));
      expect(queryService.receivedGroupId, equals(groupId));
      expect(
        queryService.receivedOrderBy,
        equals([const OrderBy('contractName', descending: false)]),
      );
    });
  });
}

class _FakeDvcPointContractQueryService
    implements DvcPointContractQueryService {
  _FakeDvcPointContractQueryService(this._contracts);

  final List<DvcPointContractDto> _contracts;
  String? receivedGroupId;
  List<OrderBy>? receivedOrderBy;

  @override
  Future<List<DvcPointContractDto>> getDvcPointContractsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    receivedGroupId = groupId;
    receivedOrderBy = orderBy;
    return _contracts;
  }
}
