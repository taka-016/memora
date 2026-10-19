import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';

class SaveDvcPointContractsUsecase {
  SaveDvcPointContractsUsecase(this._dvcPointContractRepository);

  final DvcPointContractRepository _dvcPointContractRepository;

  Future<void> execute({
    required String groupId,
    required List<DvcPointContractDto> contracts,
    Map<String, int> expectedVersions = const {},
    List<DvcPointContractDto> originalContracts = const [],
  }) async {
    await _dvcPointContractRepository.saveDvcPointContracts(
      groupId,
      DvcPointContractMapper.toEntityList(contracts),
      expectedVersions: Map.unmodifiable(expectedVersions),
      originalContracts: DvcPointContractMapper.toEntityList(originalContracts),
    );
  }
}
