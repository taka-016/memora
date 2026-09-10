import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_mapper.dart';

class SqliteMemberQueryService implements MemberQueryService {
  SqliteMemberQueryService(this.db);
  final OfflineDatabase db;
  @override
  Future<List<MemberDto>> getMembers({List<OrderBy>? orderBy}) async => (await db.rows('members', orderBy: orderBy)).map(SqliteMemberMapper.fromRow).toList();
  @override
  Future<List<MemberDto>> getMembersByOwnerId(String ownerId, {List<OrderBy>? orderBy}) async => (await db.rows('members', where: 'owner_id = ?', args: [ownerId], orderBy: orderBy)).map(SqliteMemberMapper.fromRow).toList();
  @override
  Future<MemberDto?> getMemberById(String memberId) async => _one('id', memberId);
  @override
  Future<MemberDto?> getMemberByAccountId(String accountId) async => _one('account_id', accountId);
  Future<MemberDto?> _one(String field, String value) async {
    final rows = await db.rows('members', where: '$field = ?', args: [value]);
    return rows.isEmpty ? null : SqliteMemberMapper.fromRow(rows.first);
  }
}
