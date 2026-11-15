import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';

class CheckMemberExistsUseCase {
  final MemberQueryService _memberQueryService;

  CheckMemberExistsUseCase(this._memberQueryService);

  Future<MemberDto?> execute(String accountId) async {
    final existingMember = await _memberQueryService.getMemberByAccountId(
      accountId,
    );
    return existingMember;
  }
}
