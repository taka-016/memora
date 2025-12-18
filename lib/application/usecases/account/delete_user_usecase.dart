import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  return DeleteUserUseCase(
    authService: ref.watch(authServiceProvider),
    memberQueryService: ref.watch(memberQueryServiceProvider),
    memberRepository: ref.watch(memberRepositoryProvider),
  );
});

class DeleteUserUseCase {
  const DeleteUserUseCase({
    required this.authService,
    required this.memberQueryService,
    required this.memberRepository,
  });

  final AuthService authService;
  final MemberQueryService memberQueryService;
  final MemberRepository memberRepository;

  Future<void> execute() async {
    // 現在のユーザーを取得
    final currentUser = await authService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('現在のユーザーが取得できませんでした');
    }

    // ユーザーに紐づくメンバーを取得
    final member = await memberQueryService.getMemberByAccountId(
      currentUser.id,
    );
    if (member == null) {
      throw Exception('メンバーが取得できませんでした');
    }

    // メンバーのaccountIdをnullにする
    await memberRepository.nullifyAccountId(member.id);

    // アカウントを削除
    await authService.deleteUser();
  }
}
