import 'package:memora/domain/entities/member/member_event.dart';
import 'package:memora/domain/repositories/member/member_event_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_event_mapper.dart';

class SqliteMemberEventRepository implements MemberEventRepository {
  SqliteMemberEventRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<String> saveMemberEvent(MemberEvent memberEvent) async => db.transaction(() async {
    await db.customStatement('DELETE FROM member_events WHERE member_id = ? AND year = ?', [memberEvent.memberId, memberEvent.year]);
    if (memberEvent.memo.isEmpty) return '';
    final id = '${Uri.encodeComponent(memberEvent.memberId)}_${memberEvent.year}';
    await db.insertRow('member_events', SqliteMemberEventMapper.toRow(memberEvent.copyWith(id: id)));
    return id;
  });
  @override
  Future<void> deleteMemberEvent(String memberEventId) async => db.deleteRows('member_events', 'id', memberEventId);
  @override
  Future<void> deleteMemberEventsByMemberId(String memberId) async => db.deleteRows('member_events', 'member_id', memberId);
}
