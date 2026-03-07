import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final checkMemberExistsUseCaseProvider = Provider<CheckMemberExistsUseCase>((
  ref,
) {
  return CheckMemberExistsUseCase(ref.watch(memberQueryServiceProvider));
});

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
