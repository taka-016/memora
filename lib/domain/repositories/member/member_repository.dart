import 'package:memora/domain/entities/member/member.dart';

abstract class MemberRepository {
  Future<void> saveMember(Member member);
  Future<void> updateMember(Member member);
  Future<void> deleteMember(String memberId);
  Future<void> nullifyAccountId(String memberId);
}
