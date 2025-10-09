import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final getCurrentMemberUsecaseProvider = Provider<GetCurrentMemberUseCase>((
  ref,
) {
  return GetCurrentMemberUseCase(
    ref.watch(memberRepositoryProvider),
    ref.watch(authServiceProvider),
  );
});

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
