import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';

void main() {
  group('DvcPointContractMapper', () {
    test('Dtoとエンティティを相互変換できる', () {
      final dto = DvcPointContractDto(
        id: 'contract-1',
        groupId: 'group-1',
        contractName: '契約A',
        contractStartYearMonth: DateTime(2024, 10),
        contractEndYearMonth: DateTime(2042, 9),
        useYearStartMonth: 10,
        annualPoint: 200,
      );

      final entity = DvcPointContractMapper.toEntity(dto);
      final restored = DvcPointContractMapper.toDto(entity);

      expect(entity.id, 'contract-1');
      expect(restored.contractName, '契約A');
      expect(restored.annualPoint, 200);
    });

    test('リスト変換ができる', () {
      final dtos = [
        DvcPointContractDto(
          id: 'contract-1',
          groupId: 'group-1',
          contractName: '契約A',
          contractStartYearMonth: DateTime(2024, 10),
          contractEndYearMonth: DateTime(2042, 9),
          useYearStartMonth: 10,
          annualPoint: 200,
        ),
      ];

      final entities = DvcPointContractMapper.toEntityList(dtos);
      final restored = DvcPointContractMapper.toDtoList(entities);

      expect(entities, hasLength(1));
      expect(restored.first.id, 'contract-1');
    });
  });
}
