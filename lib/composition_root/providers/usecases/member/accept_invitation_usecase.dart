import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';

final acceptInvitationUseCaseProvider = Provider<AcceptInvitationUseCase>((
  ref,
) {
  return AcceptInvitationUseCase(
    ref.watch(memberInvitationQueryServiceProvider),
    ref.watch(memberInvitationRepositoryProvider),
    ref.watch(memberRepositoryProvider),
    ref.watch(memberQueryServiceProvider),
    ref.watch(appClockProvider),
  );
});
