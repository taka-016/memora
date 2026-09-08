import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/mappers/member/member_invitation_mapper.dart';
import 'package:memora/application/queries/member/member_invitation_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:uuid/uuid.dart';
import 'package:memora/domain/entities/member/member_invitation.dart';
import 'package:memora/domain/repositories/member/member_invitation_repository.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/member/create_or_update_member_invitation_usecase.dart';

final createOrUpdateMemberInvitationUsecaseProvider =
    Provider<CreateOrUpdateMemberInvitationUsecase>((ref) {
      return CreateOrUpdateMemberInvitationUsecase(
        ref.watch(memberInvitationRepositoryProvider),
        ref.watch(memberInvitationQueryServiceProvider),
      );
    });
