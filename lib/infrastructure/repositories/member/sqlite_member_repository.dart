import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/mappers/member/sqlite_member_mapper.dart';

class SqliteMemberRepository implements MemberRepository {
  SqliteMemberRepository(this.db);
  final OfflineDatabase db;
  @override
  Future<void> saveMember(Member member) async => db.insertRow('members', SqliteMemberMapper.toRow(member.copyWith(id: const Uuid().v4())));
  @override
  Future<void> updateMember(Member member) async => db.updateRow('members', member.id, SqliteMemberMapper.toRow(member));
  @override
  Future<void> deleteMember(String memberId) async => db.deleteRows('members', 'id', memberId);
}
