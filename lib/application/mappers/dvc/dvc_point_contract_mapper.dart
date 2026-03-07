import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';

class DvcPointContractMapper {
  static DvcPointContract toEntity(DvcPointContractDto dto) {
    return DvcPointContract(
      id: dto.id,
      groupId: dto.groupId,
      contractName: dto.contractName,
      contractStartYearMonth: dto.contractStartYearMonth,
      contractEndYearMonth: dto.contractEndYearMonth,
      useYearStartMonth: dto.useYearStartMonth,
      annualPoint: dto.annualPoint,
    );
  }

  static DvcPointContractDto toDto(DvcPointContract entity) {
    return DvcPointContractDto(
      id: entity.id,
      groupId: entity.groupId,
      contractName: entity.contractName,
      contractStartYearMonth: entity.contractStartYearMonth,
      contractEndYearMonth: entity.contractEndYearMonth,
      useYearStartMonth: entity.useYearStartMonth,
      annualPoint: entity.annualPoint,
    );
  }

  static List<DvcPointContract> toEntityList(List<DvcPointContractDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<DvcPointContractDto> toDtoList(List<DvcPointContract> entities) {
    return entities.map(toDto).toList();
  }
}
