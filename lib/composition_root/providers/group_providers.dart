import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_event_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/application/usecases/group/get_group_events_usecase.dart';
import 'package:memora/application/usecases/group/get_group_with_members_by_id_usecase.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/save_group_event_usecase.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';

final createGroupUsecaseProvider = Provider<CreateGroupUsecase>((ref) {
  return CreateGroupUsecase(ref.watch(groupRepositoryProvider));
});

final deleteGroupEventUsecaseProvider = Provider<DeleteGroupEventUsecase>((
  ref,
) {
  return DeleteGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});

final deleteGroupUsecaseProvider = Provider<DeleteGroupUsecase>((ref) {
  return DeleteGroupUsecase(
    ref.watch(groupRepositoryProvider),
    ref.watch(groupEventRepositoryProvider),
    ref.watch(tripEntryRepositoryProvider),
  );
});

final getGroupEventsUsecaseProvider = Provider<GetGroupEventsUsecase>((ref) {
  return GetGroupEventsUsecase(ref.watch(groupEventQueryServiceProvider));
});

final getGroupWithMembersByIdUsecaseProvider =
    Provider<GetGroupWithMembersByIdUsecase>((ref) {
      return GetGroupWithMembersByIdUsecase(
        ref.watch(groupQueryServiceProvider),
      );
    });

final getGroupsWithMembersUsecaseProvider =
    Provider<GetGroupsWithMembersUsecase>((ref) {
      return GetGroupsWithMembersUsecase(ref.watch(groupQueryServiceProvider));
    });

final getManagedGroupsWithMembersUsecaseProvider =
    Provider<GetManagedGroupsWithMembersUsecase>((ref) {
      return GetManagedGroupsWithMembersUsecase(
        ref.watch(groupQueryServiceProvider),
      );
    });

final saveGroupEventUsecaseProvider = Provider<SaveGroupEventUsecase>((ref) {
  return SaveGroupEventUsecase(ref.watch(groupEventRepositoryProvider));
});

final updateGroupUsecaseProvider = Provider<UpdateGroupUsecase>((ref) {
  return UpdateGroupUsecase(ref.watch(groupRepositoryProvider));
});
