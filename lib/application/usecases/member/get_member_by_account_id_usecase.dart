import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';

class GetMemberByAccountIdUseCase {
  final MemberQueryService _memberQueryService;

  GetMemberByAccountIdUseCase(this._memberQueryService);

  Future<MemberDto?> execute(String accountId) async {
    return _memberQueryService.getMemberByAccountId(accountId);
  }
}
