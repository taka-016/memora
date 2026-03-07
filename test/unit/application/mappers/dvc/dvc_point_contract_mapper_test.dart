import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

void main() {
  group('DvcPointContractMapper', () {
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
  });
}
