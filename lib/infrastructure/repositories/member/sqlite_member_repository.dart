import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_mapper.dart';

class SqliteMemberRepository implements MemberRepository {
  SqliteMemberRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<void> saveMember(Member member) async => db.insertRow(
    'members',
    SqliteMemberMapper.toRow(member.copyWith(id: const Uuid().v4())),
  );
  @override
  Future<void> updateMember(Member member) async =>
      db.updateRow('members', member.id, SqliteMemberMapper.toRow(member));
  @override
  Future<void> deleteMember(String memberId, {int? expectedVersion}) async =>
      db.transaction(() async {
        final rows = await db.rows(
          'members',
          where: 'id = ?',
          args: [memberId],
        );
        if (rows.isEmpty) return;
        await db.insertRow('deleted_members', rows.single);
        await db.deleteRows('members', 'id', memberId);
      });
}
