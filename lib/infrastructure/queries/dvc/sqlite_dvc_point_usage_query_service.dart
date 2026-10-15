import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_point_usage_mapper.dart';

class SqliteDvcPointUsageQueryService implements DvcPointUsageQueryService {
  SqliteDvcPointUsageQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
    String? contractId,
  }) async => (await db.rows(
    'dvc_point_usages',
    where: contractId == null
        ? 'group_id = ?'
        : 'group_id = ? AND contract_id = ?',
    args: [groupId, ?contractId],
    orderBy: orderBy,
  )).map(SqliteDvcPointUsageMapper.fromRow).toList();
}
