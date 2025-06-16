import 'package:memora/domain/entities/member.dart';

abstract class MemberRepository {
  Future<List<Member>> getMembers();
  Future<void> saveMember(Member member);
  Future<void> deleteMember(String memberId);
  Future<Member?> getMemberById(String memberId);
}