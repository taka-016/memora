import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';

final getCurrentMemberUsecaseProvider = Provider<GetCurrentMemberUseCase>((
  ref,
) {
  return GetCurrentMemberUseCase(
    ref.watch(memberQueryServiceProvider),
    ref.watch(authServiceProvider),
  );
});

class GetCurrentMemberUseCase {
  final MemberQueryService _memberQueryService;
  final AuthService _authService;

  GetCurrentMemberUseCase(this._memberQueryService, this._authService);

  Future<Member?> execute() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return null;
    }

    return await _memberQueryService.getMemberByAccountId(currentUser.id);
  }
}
