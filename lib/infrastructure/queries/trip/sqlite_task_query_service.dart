import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/queries/trip/task_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/trip/sqlite_task_mapper.dart';

class SqliteTaskQueryService implements TaskQueryService {
  SqliteTaskQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<TaskDto>> getTasksByTripId(
    String tripId, {
    List<OrderBy>? orderBy,
  }) async => (await db.rows(
    'tasks',
    where: 'trip_id = ?',
    args: [tripId],
    orderBy: orderBy,
  )).map(SqliteTaskMapper.fromRow).toList();
}
