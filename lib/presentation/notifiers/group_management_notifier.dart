import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/mappers/group/group_member_mapper.dart';
import 'package:memora/application/usecases/group/create_group_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_usecase.dart';
import 'package:memora/application/usecases/group/get_managed_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/group/update_group_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/group_management_state.dart';

export 'group_management_state.dart';

final groupManagementNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<GroupManagementNotifier, GroupManagementState, MemberDto>(
      GroupManagementNotifier.new,
      retry: (_, _) => null,
    );

class GroupManagementNotifier extends AsyncNotifier<GroupManagementState> {
  GroupManagementNotifier(this._currentMember);

  final MemberDto _currentMember;
  bool _isMutationInProgress = false;

  @override
  Future<GroupManagementState> build() async {
    try {
      final groups = await _getGroups();
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

  Future<bool> refreshGroups() async {
    if (_isMutationInProgress) {
      return false;
    }

    ref.invalidateSelf();
    return true;
  }

  Future<List<GroupMemberDto>?> loadAvailableMembers(String groupId) async {
    try {
      final members = await ref
          .read(getManagedMembersUsecaseProvider)
          .execute(_currentMember);
      if (!ref.mounted) {
        return null;
      }
      return GroupMemberMapper.fromMemberList(members, groupId);
    } catch (e, stack) {
      logger.e(
        'GroupManagementNotifier.loadAvailableMembers: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<bool> createGroup(GroupDto group) async {
    return _runMutation(
      operationName: 'createGroup',
      execute: () async {
        await ref.read(createGroupUsecaseProvider).execute(group);
      },
    );
  }

  Future<bool> updateGroup(GroupDto group) async {
    return _runMutation(
      operationName: 'updateGroup',
      execute: () => ref.read(updateGroupUsecaseProvider).execute(group),
    );
  }

  Future<bool> deleteGroup(String groupId) async {
    return _runMutation(
      operationName: 'deleteGroup',
      execute: () => ref.read(deleteGroupUsecaseProvider).execute(groupId),
    );
  }

  Future<bool> _runMutation({
    required String operationName,
    required Future<void> Function() execute,
  }) async {
    if (state.value == null || _isMutationInProgress) {
      return false;
    }

    _isMutationInProgress = true;
    final keepAliveLink = ref.keepAlive();
    try {
      await execute();
      if (!ref.mounted) {
        return false;
      }
      ref.invalidateSelf();
      return true;
    } catch (e, stack) {
      if (!ref.mounted) {
        return false;
      }
      logger.e(
        'GroupManagementNotifier.$operationName: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      _isMutationInProgress = false;
      keepAliveLink.close();
    }
  }

  Future<List<GroupDto>> _getGroups() {
    return ref
        .read(getManagedGroupsWithMembersUsecaseProvider)
        .execute(_currentMember);
  }
}
