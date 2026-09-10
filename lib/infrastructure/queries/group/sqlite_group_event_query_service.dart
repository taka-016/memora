import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/group/sqlite_group_event_mapper.dart';

class SqliteGroupEventQueryService implements GroupEventQueryService {
  SqliteGroupEventQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<GroupEventDto>> getGroupEventsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async => (await db.rows(
    'group_events',
    where: 'group_id = ?',
    args: [groupId],
    orderBy: orderBy,
  )).map(SqliteGroupEventMapper.fromRow).toList();
}
