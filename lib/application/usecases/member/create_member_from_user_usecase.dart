import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/domain/entities/member/member.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/core/app_logger.dart';

final createMemberFromUserUseCaseProvider =
    Provider<CreateMemberFromUserUseCase>((ref) {
      return CreateMemberFromUserUseCase(ref.watch(memberRepositoryProvider));
    });

class CreateMemberFromUserUseCase {
  final MemberRepository _memberRepository;

  CreateMemberFromUserUseCase(this._memberRepository);

  Future<bool> execute({
    required String userId,
    required String loginId,
  }) async {
    try {
      final newMember = Member(
        id: '',
        displayName: loginId,
        accountId: userId,
        email: loginId,
      );

      await _memberRepository.saveMember(newMember);
      return true;
    } catch (e, stack) {
      logger.e(
        'CreateMemberFromUserUseCase.execute: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
