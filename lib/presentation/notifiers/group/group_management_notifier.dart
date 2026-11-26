import 'package:memora/presentation/notifiers/group/group_mutation_coordinator.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/group/group_management_state.dart';

export 'group_management_state.dart';

final groupManagementNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<GroupManagementNotifier, GroupManagementState, MemberDto>(
      GroupManagementNotifier.new,
      retry: (_, _) => null,
    );

class GroupManagementNotifier extends AsyncNotifier<GroupManagementState> {
  GroupManagementNotifier(this._currentMember);

  final MemberDto _currentMember;
  bool _isOperationInProgress = false;

  @override
  Future<GroupManagementState> build() async {
    try {
      final groups = await _getManagedGroupsWithMembers();
      return GroupManagementState(groups: groups);
    } catch (e, stack) {
      logger.e(
        'GroupManagementNotifier.build: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<bool> refreshGroups() {
    return _runExclusiveOperation(execute: _refreshGroups);
  }

  Future<bool> createGroup(GroupDto group) {
    return _runMutation(
      operationName: 'createGroup',
      execute: () => ref
          .read(groupMutationCoordinatorProvider)
          .createGroup(group, refreshGroups: _refreshGroups),
    );
  }

  Future<bool> updateGroup(GroupDto group) {
    return _runMutation(
      operationName: 'updateGroup',
      execute: () => ref
          .read(groupMutationCoordinatorProvider)
          .updateGroup(group, refreshGroups: _refreshGroups),
    );
  }

  Future<bool> deleteGroup(String groupId, {int? expectedVersion}) {
    return _runMutation(
      operationName: 'deleteGroup',
      execute: () => ref
          .read(groupMutationCoordinatorProvider)
          .deleteGroup(
            groupId,
            expectedVersion: expectedVersion,
            refreshGroups: _refreshGroups,
          ),
    );
  }

  Future<bool> _runMutation({
    required String operationName,
    required Future<void> Function() execute,
  }) async {
    return _runExclusiveOperation(
      requireValue: true,
      execute: () async {
        try {
          await execute();
        } catch (e, stack) {
          if (!ref.mounted) {
            return;
          }
          logger.e(
            'GroupManagementNotifier.$operationName: ${e.toString()}',
            error: e,
            stackTrace: stack,
          );
          rethrow;
        }
      },
    );
  }

  Future<bool> _runExclusiveOperation({
    bool requireValue = false,
    required Future<void> Function() execute,
  }) async {
    if (_isOperationInProgress ||
        state.isLoading ||
        (requireValue && state.value == null)) {
      return false;
    }

    _isOperationInProgress = true;
    final keepAliveLink = ref.keepAlive();
    try {
      await execute();
      return ref.mounted;
    } finally {
      _isOperationInProgress = false;
      keepAliveLink.close();
    }
  }

  Future<List<GroupDto>> _refreshGroups() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // 読み込み失敗はbuildで記録し、AsyncErrorをViewへ通知する。
    }
    return ref.mounted ? state.value?.groups ?? const [] : const [];
  }

  Future<List<GroupDto>> _getManagedGroupsWithMembers() {
    return ref
        .read(getManagedGroupsWithMembersUsecaseProvider)
        .execute(_currentMember);
  }
}
