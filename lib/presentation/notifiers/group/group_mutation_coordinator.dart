import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

final groupMutationCoordinatorProvider = Provider<GroupMutationCoordinator>(
  GroupMutationCoordinator.new,
);

class GroupMutationCoordinator {
  GroupMutationCoordinator(this.ref);

  final Ref ref;

  Future<void> createGroup(
    GroupDto group, {
    required Future<void> Function() refreshGroups,
  }) async {
    await ref.read(createGroupUsecaseProvider).execute(group);
    if (!ref.mounted) return;
    await refreshGroups();
    await _refreshCommonData();
  }

  Future<void> updateGroup(
    GroupDto group, {
    required Future<List<GroupDto>> Function() refreshGroups,
  }) async {
    await ref.read(updateGroupUsecaseProvider).execute(group);
    if (!ref.mounted) return;
    final groups = await refreshGroups();
    await _refreshCommonData();
    if (!ref.mounted) return;
    final refreshed = groups.where((value) => value.id == group.id).firstOrNull;
    final selection = ref.read(groupTimelineGroupSelectionNotifierProvider);
    if (refreshed != null &&
        selection.status == GroupTimelineGroupSelectionStatus.loaded) {
      ref
          .read(groupTimelineGroupSelectionNotifierProvider.notifier)
          .setLoadedGroups(
            memberId: selection.memberId!,
            groups: [
              for (final value in selection.groups)
                value.id == refreshed.id ? refreshed : value,
            ],
          );
    }
  }

  Future<void> deleteGroup(
    String groupId, {
    int? expectedVersion,
    required Future<void> Function() refreshGroups,
  }) async {
    await ref
        .read(deleteGroupUsecaseProvider)
        .execute(groupId, expectedVersion: expectedVersion);
    if (!ref.mounted) return;
    ref.read(groupTimelineGroupSelectionNotifierProvider.notifier).reset();
    try {
      await ref.read(refreshSelectedAndroidWidgetCacheProvider)();
    } catch (error, stackTrace) {
      logger.w('削除後のウィジェット更新に失敗しました', error: error, stackTrace: stackTrace);
    }
    if (!ref.mounted) return;
    await refreshGroups();
    await _refreshCommonData();
  }

  Future<void> _refreshCommonData() async {
    if (ref.mounted &&
        ref.read(startupCommonDataNotifierProvider.exists) &&
        ref.read(startupCommonDataOwnerProvider) != null) {
      await ref
          .read(startupCommonDataNotifierProvider.notifier)
          .refreshAfterChange();
    }
  }
}
