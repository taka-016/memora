import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_invitation_dto.dart';
import 'package:memora/application/mappers/member/member_mapper.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/application/queries/member/member_query_service.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/domain/repositories/member/member_repository.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/core/app_logger.dart';
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
