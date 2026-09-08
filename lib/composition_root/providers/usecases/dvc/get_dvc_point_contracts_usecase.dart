import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_contracts_usecase.dart';

final getDvcPointContractsUsecaseProvider =
    Provider<GetDvcPointContractsUsecase>((ref) {
      return GetDvcPointContractsUsecase(
        ref.watch(dvcPointContractQueryServiceProvider),
      );
    });
