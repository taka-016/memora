import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/dvc/save_dvc_point_contracts_usecase.dart';

final saveDvcPointContractsUsecaseProvider =
    Provider<SaveDvcPointContractsUsecase>((ref) {
      return SaveDvcPointContractsUsecase(
        ref.watch(dvcPointContractRepositoryProvider),
      );
    });
