import 'package:memora/application/dtos/dvc/dvc_limited_point_dto.dart';
import 'package:memora/application/queries/dvc/dvc_limited_point_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/dvc/sqlite_dvc_limited_point_mapper.dart';

class SqliteDvcLimitedPointQueryService implements DvcLimitedPointQueryService {
  SqliteDvcLimitedPointQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<DvcLimitedPointDto>> getDvcLimitedPointsByGroupId(String groupId, {List<OrderBy>? orderBy}) async => (await db.rows('dvc_limited_points', where: 'group_id = ?', args: [groupId], orderBy: orderBy)).map(SqliteDvcLimitedPointMapper.fromRow).toList();
}
