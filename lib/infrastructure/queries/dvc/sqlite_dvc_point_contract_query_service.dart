import 'package:memora/application/dtos/dvc/dvc_point_contract_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_contract_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_point_contract_mapper.dart';

class SqliteDvcPointContractQueryService
    implements DvcPointContractQueryService {
  SqliteDvcPointContractQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<DvcPointContractDto>> getDvcPointContractsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async => (await db.rows(
    'dvc_point_contracts',
    where: 'group_id = ?',
    args: [groupId],
    orderBy: orderBy,
  )).map(SqliteDvcPointContractMapper.fromRow).toList();
}
