import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/current_member_resolver.dart';
import 'package:memora/application/services/authenticated_current_member_resolver.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/local_current_member_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/member/accept_invitation_usecase.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';
import 'package:memora/application/usecases/member/check_member_exists_usecase.dart';
import 'package:memora/application/usecases/member/create_member_from_user_usecase.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/application/usecases/member/get_current_member_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/application/usecases/member/get_member_events_usecase.dart';
import 'package:memora/application/usecases/member/save_member_event_usecase.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final acceptInvitationUseCaseProvider = Provider<AcceptInvitationUseCase>((
  ref,
) {
  ref.watch(appCapabilitiesProvider).requireAvailable(AppFeature.invitations);
  return AcceptInvitationUseCase(
    ref.watch(memberInvitationQueryServiceProvider),
    ref.watch(memberInvitationRepositoryProvider),
    ref.watch(memberRepositoryProvider),
    ref.watch(memberQueryServiceProvider),
    ref.watch(appClockProvider),
  );
});

final calculateSchoolGradeUsecaseProvider =
    Provider<CalculateSchoolGradeUsecase>((ref) {
      return CalculateSchoolGradeUsecase();
    });

final calculateYakudoshiUsecaseProvider = Provider<CalculateYakudoshiUsecase>((
  ref,
) {
  return CalculateYakudoshiUsecase();
});

final checkMemberExistsUseCaseProvider = Provider<CheckMemberExistsUseCase>((
  ref,
) {
  return CheckMemberExistsUseCase(ref.watch(memberQueryServiceProvider));
});

final createMemberFromUserUseCaseProvider =
    Provider<CreateMemberFromUserUseCase>((ref) {
      return CreateMemberFromUserUseCase(ref.watch(memberRepositoryProvider));
    });

final createMemberUsecaseProvider = Provider<CreateMemberUsecase>((ref) {
  return CreateMemberUsecase(ref.watch(memberRepositoryProvider));
});

final createOrUpdateMemberInvitationUsecaseProvider =
    Provider<CreateOrUpdateMemberInvitationUsecase>((ref) {
      ref
          .watch(appCapabilitiesProvider)
          .requireAvailable(AppFeature.invitations);
      return CreateOrUpdateMemberInvitationUsecase(
        ref.watch(memberInvitationRepositoryProvider),
        ref.watch(memberInvitationQueryServiceProvider),
      );
    });

final deleteMemberUsecaseProvider = Provider<DeleteMemberUsecase>((ref) {
  return DeleteMemberUsecase(
    ref.watch(memberRepositoryProvider),
    ref.watch(groupRepositoryProvider),
    ref.watch(memberEventRepositoryProvider),
  );
});

final currentMemberResolverProvider = Provider<CurrentMemberResolver>((ref) {
  return switch (ref.watch(appModeProvider)) {
    AppMode.offline => LocalCurrentMemberResolver(),
    AppMode.online => AuthenticatedCurrentMemberResolver(
      ref.watch(memberQueryServiceProvider),
      ref.watch(authServiceProvider),
    ),
  };
});

final getCurrentMemberUsecaseProvider = Provider<GetCurrentMemberUseCase>((
  ref,
) {
  return GetCurrentMemberUseCase(ref.watch(currentMemberResolverProvider));
});

final getManagedMembersUsecaseProvider = Provider<GetManagedMembersUsecase>((
  ref,
) {
  return GetManagedMembersUsecase(ref.watch(memberQueryServiceProvider));
});

final getMemberByIdUsecaseProvider = Provider<GetMemberByIdUseCase>((ref) {
  return GetMemberByIdUseCase(ref.watch(memberQueryServiceProvider));
});

final getMemberEventsUsecaseProvider = Provider<GetMemberEventsUsecase>((ref) {
  return GetMemberEventsUsecase(ref.watch(memberEventQueryServiceProvider));
});

final saveMemberEventUsecaseProvider = Provider<SaveMemberEventUsecase>((ref) {
  return SaveMemberEventUsecase(ref.watch(memberEventRepositoryProvider));
});

final updateMemberUsecaseProvider = Provider<UpdateMemberUsecase>((ref) {
  return UpdateMemberUsecase(ref.watch(memberRepositoryProvider));
});
