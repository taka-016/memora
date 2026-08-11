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

final groupManagementNotifierProvider =
    NotifierProvider<GroupManagementNotifier, GroupManagementState>(
      GroupManagementNotifier.new,
    );

class GroupManagementNotifier extends Notifier<GroupManagementState> {
  MemberDto? _currentMember;
  var _loadGeneration = 0;

  @override
  GroupManagementState build() {
    return const GroupManagementState();
  }

  Future<void> load(MemberDto currentMember) async {
    _currentMember = currentMember;
    final loadGeneration = ++_loadGeneration;
    state = const GroupManagementState(status: GroupManagementStatus.loading);

    try {
      final groups = await _getGroups(currentMember);
      if (loadGeneration != _loadGeneration) {
        return;
      }
      state = GroupManagementState(
        status: GroupManagementStatus.loaded,
        groups: groups,
      );
    } catch (e, stack) {
      if (loadGeneration != _loadGeneration) {
        return;
      }
      logger.e(
        'GroupManagementNotifier.load: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = GroupManagementState(
        status: GroupManagementStatus.error,
        errorMessage: 'データの読み込みに失敗しました: $e',
      );
    }
  }

  Future<void> refresh() async {
    final currentMember = _currentMember;
    if (currentMember == null) {
      return;
    }

    state = state.copyWith(
      refreshStatus: GroupManagementRefreshStatus.loading,
      errorMessage: '',
    );
    try {
      final groups = await _getGroups(currentMember);
      state = state.copyWith(
        status: GroupManagementStatus.loaded,
        refreshStatus: GroupManagementRefreshStatus.idle,
        groups: groups,
        errorMessage: '',
      );
    } catch (e, stack) {
      logger.e(
        'GroupManagementNotifier.refresh: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        refreshStatus: GroupManagementRefreshStatus.error,
        errorMessage: 'データの読み込みに失敗しました: $e',
      );
    }
  }

  Future<List<GroupMemberDto>?> loadAvailableMembers(String groupId) async {
    final currentMember = _currentMember;
    if (currentMember == null) {
      return null;
    }

    state = state.copyWith(
      operationType: GroupManagementOperationType.loadAvailableMembers,
      operationStatus: GroupManagementOperationStatus.loading,
      errorMessage: '',
    );
    try {
      final members = await ref
          .read(getManagedMembersUsecaseProvider)
          .execute(currentMember);
      final availableMembers = GroupMemberMapper.fromMemberList(
        members,
        groupId,
      );
      state = state.copyWith(
        operationStatus: GroupManagementOperationStatus.success,
        availableMembers: availableMembers,
        errorMessage: '',
      );
      return availableMembers;
    } catch (e, stack) {
      logger.e(
        'GroupManagementNotifier.loadAvailableMembers: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        operationStatus: GroupManagementOperationStatus.error,
        errorMessage: 'メンバー情報の取得に失敗しました: $e',
      );
      return null;
    }
  }

  Future<bool> createGroup(GroupDto group) async {
    return _runMutation(
      type: GroupManagementOperationType.create,
      failureMessage: '作成に失敗しました',
      execute: () async {
        await ref.read(createGroupUsecaseProvider).execute(group);
      },
    );
  }

  Future<bool> updateGroup(GroupDto group) async {
    return _runMutation(
      type: GroupManagementOperationType.update,
      failureMessage: '更新に失敗しました',
      execute: () => ref.read(updateGroupUsecaseProvider).execute(group),
    );
  }

  Future<bool> deleteGroup(String groupId) async {
    return _runMutation(
      type: GroupManagementOperationType.delete,
      failureMessage: '削除に失敗しました',
      execute: () => ref.read(deleteGroupUsecaseProvider).execute(groupId),
    );
  }

  Future<bool> _runMutation({
    required GroupManagementOperationType type,
    required String failureMessage,
    required Future<void> Function() execute,
  }) async {
    final currentMember = _currentMember;
    if (currentMember == null) {
      return false;
    }

    state = state.copyWith(
      operationType: type,
      operationStatus: GroupManagementOperationStatus.loading,
      errorMessage: '',
    );
    try {
      await execute();
      final groups = await _getGroups(currentMember);
      state = state.copyWith(
        status: GroupManagementStatus.loaded,
        refreshStatus: GroupManagementRefreshStatus.idle,
        operationStatus: GroupManagementOperationStatus.success,
        groups: groups,
        errorMessage: '',
      );
      return true;
    } catch (e, stack) {
      logger.e(
        'GroupManagementNotifier.${type.name}: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = state.copyWith(
        operationStatus: GroupManagementOperationStatus.error,
        errorMessage: '$failureMessage: $e',
      );
      return false;
    }
  }

  Future<List<GroupDto>> _getGroups(MemberDto currentMember) {
    return ref
        .read(getManagedGroupsWithMembersUsecaseProvider)
        .execute(currentMember);
  }
}
