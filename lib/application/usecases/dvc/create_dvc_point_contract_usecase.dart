import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/dvc/dvc_point_contract.dart';
import 'package:memora/domain/repositories/dvc/dvc_point_contract_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:uuid/uuid.dart';

final createDvcPointContractUsecaseProvider =
    Provider<CreateDvcPointContractUsecase>((ref) {
      return CreateDvcPointContractUsecase(
        ref.watch(dvcPointContractRepositoryProvider),
      );
    });

class CreateDvcPointContractUsecase {
  CreateDvcPointContractUsecase(this._repository);

  final DvcPointContractRepository _repository;

  Future<void> execute({
    required String groupId,
    required String contractName,
    required int useYearStartMonth,
    required int annualPoint,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final startYear = today.month >= useYearStartMonth
        ? today.year
        : today.year - 1;
    final contractStart = DateTime(startYear, useYearStartMonth);
    final contractEnd = DateTime(startYear + 30, useYearStartMonth);

    final contract = DvcPointContract(
      id: const Uuid().v4(),
      groupId: groupId,
      contractName: contractName,
      contractStartYearMonth: contractStart,
      contractEndYearMonth: contractEnd,
      useYearStartMonth: useYearStartMonth,
      annualPoint: annualPoint,
    );

    await _repository.saveDvcPointContract(contract);
  }
}
