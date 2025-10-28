import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/domain/value_objects/order_by.dart';

abstract class MemberQueryService {
  Future<List<MemberDto>> getMembers({List<OrderBy>? orderBy});
  Future<MemberDto?> getMemberById(String memberId);
  Future<MemberDto?> getMemberByAccountId(String accountId);
  Future<List<MemberDto>> getMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? orderBy,
  });
}
