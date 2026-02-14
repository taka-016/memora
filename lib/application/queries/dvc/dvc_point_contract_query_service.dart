import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class DvcPointContractQueryService {
  Future<List<DvcPointContractDto>> getDvcPointContractsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  });
}
