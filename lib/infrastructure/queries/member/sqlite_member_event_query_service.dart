import 'package:memora/application/dtos/member/member_event_dto.dart';
import 'package:memora/application/queries/member/member_event_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_event_mapper.dart';

class SqliteMemberEventQueryService implements MemberEventQueryService {
  SqliteMemberEventQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<MemberEventDto>> getMemberEventsByMemberIds(List<String> memberIds, {List<OrderBy>? orderBy}) async {
    if (memberIds.isEmpty) return [];
    final ids = memberIds.toSet().toList();
    return (await db.rows('member_events', where: 'member_id IN (${List.filled(ids.length, '?').join(', ')})', args: ids, orderBy: orderBy)).map(SqliteMemberEventMapper.fromRow).toList();
  }
}
