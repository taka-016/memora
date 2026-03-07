import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

void main() {
  group('DvcPointContractMapper', () {
    test('Dtoからエンティティへ変換できる', () {
      final dto = DvcPointContractDto(
        id: 'contract-1',
        groupId: 'group-1',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 1),
        contractEndYearMonth: DateTime(2030, 1),
        useYearStartMonth: 1,
        annualPoint: 200,
      );

      final entity = DvcPointContractMapper.toEntity(dto);

      expect(
        entity,
        DvcPointContract(
          id: 'contract-1',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2024, 1),
          contractEndYearMonth: DateTime(2030, 1),
          useYearStartMonth: 1,
          annualPoint: 200,
        ),
      );
    });

    test('エンティティからDtoへ変換できる', () {
      final entity = DvcPointContract(
        id: 'contract-1',
        groupId: 'group-1',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 1),
        contractEndYearMonth: DateTime(2030, 1),
        useYearStartMonth: 1,
        annualPoint: 200,
      );

      final dto = DvcPointContractMapper.toDto(entity);

      expect(dto.id, 'contract-1');
      expect(dto.groupId, 'group-1');
      expect(dto.annualPoint, 200);
    });
  });
}
