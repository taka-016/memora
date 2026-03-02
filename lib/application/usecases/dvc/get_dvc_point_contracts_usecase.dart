import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getDvcPointContractsUsecaseProvider =
    Provider<GetDvcPointContractsUsecase>((ref) {
      return GetDvcPointContractsUsecase(
        ref.watch(dvcPointContractQueryServiceProvider),
      );
    });

class GetDvcPointContractsUsecase {
  GetDvcPointContractsUsecase(this._dvcPointContractQueryService);

  final DvcPointContractQueryService _dvcPointContractQueryService;

  Future<List<DvcPointContractDto>> execute(String groupId) async {
    return _dvcPointContractQueryService.getDvcPointContractsByGroupId(
      groupId,
      orderBy: [const OrderBy('contractName', descending: false)],
    );
  }
}
