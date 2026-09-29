import 'package:memora/application/queries/member/member_query_service.dart';

class CheckMemberExistsUseCase {
  final MemberQueryService _memberQueryService;

  CheckMemberExistsUseCase(this._memberQueryService);

  Future<bool> execute(String accountId) async {
    final existingMember = await _memberQueryService.getMemberByAccountId(
      accountId,
    );
    return existingMember != null;
  }
}
