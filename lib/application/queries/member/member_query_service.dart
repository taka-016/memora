import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class MemberQueryService {
  Future<List<MemberDto>> getMembers({List<OrderBy>? orderBy});

  Future<Member?> getMemberById(String memberId);

  Future<Member?> getMemberByAccountId(String accountId);

  Future<List<Member>> getMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? orderBy,
  });
}
