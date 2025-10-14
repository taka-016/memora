import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class MemberRepository {
  Future<List<Member>> getMembers({List<OrderBy>? orderBy});
  Future<void> saveMember(Member member);
  Future<void> updateMember(Member member);
  Future<void> deleteMember(String memberId);
  Future<Member?> getMemberById(String memberId);
  Future<Member?> getMemberByAccountId(String accountId);
  Future<List<Member>> getMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? orderBy,
  });
}
