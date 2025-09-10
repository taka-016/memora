import '../../../domain/entities/member.dart';
import '../../../domain/repositories/member_repository.dart';
import '../../interfaces/auth_service.dart';

class GetCurrentMemberUseCase {
  final MemberRepository _memberRepository;
  final AuthService _authService;

  GetCurrentMemberUseCase(this._memberRepository, this._authService);

  Future<Member?> execute() async {
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) {
      return null;
    }

    return await _memberRepository.getMemberByAccountId(currentUser.id);
  }
}
