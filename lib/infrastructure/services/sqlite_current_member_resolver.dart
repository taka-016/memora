import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/application/services/current_member_resolver.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_mapper.dart';
import 'package:memora/infrastructure/queries/member/sqlite_member_query_service.dart';
import 'package:memora/infrastructure/services/local_current_member_resolver.dart';

class SqliteCurrentMemberResolver implements CurrentMemberResolver {
  SqliteCurrentMemberResolver(
    this.db, {
    LocalCurrentMemberResolver? localResolver,
  }) : _localResolver = localResolver ?? LocalCurrentMemberResolver();
  final OfflineDatabase db;
  final LocalCurrentMemberResolver _localResolver;
  @override
  Future<MemberDto> resolve() async {
    final local = await _localResolver.resolve();
    return db.transaction(() async {
      final saved = await SqliteMemberQueryService(db).getMemberById(local.id);
      if (saved != null) return saved;
      await db.insertRow(
        'members',
        SqliteMemberMapper.toRow(MemberMapper.toEntity(local)),
      );
      return local;
    });
  }
}
