import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/application/services/auth_service.dart';

class GetCurrentMemberUseCase {
  final MemberQueryService _memberQueryService;
  final AuthService _authService;

  GetCurrentMemberUseCase(this._memberQueryService, this._authService);

  Future<MemberDto?> execute() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return null;
    }

    return await _memberQueryService.getMemberByAccountId(currentUser.id);
  }
}
