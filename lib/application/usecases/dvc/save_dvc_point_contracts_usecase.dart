import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/mappers/dvc/dvc_point_contract_mapper.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final saveDvcPointContractsUsecaseProvider =
    Provider<SaveDvcPointContractsUsecase>((ref) {
      return SaveDvcPointContractsUsecase(
        ref.watch(dvcPointContractRepositoryProvider),
      );
    });

class SaveDvcPointContractsUsecase {
  SaveDvcPointContractsUsecase(this._dvcPointContractRepository);

  final DvcPointContractRepository _dvcPointContractRepository;

  Future<void> execute({
    required String groupId,
    required List<DvcPointContractDto> contracts,
  }) async {
    await _dvcPointContractRepository.deleteDvcPointContractsByGroupId(groupId);
    for (final contract in contracts) {
      await _dvcPointContractRepository.saveDvcPointContract(
        DvcPointContractMapper.toEntity(contract),
      );
    }
  }
}
