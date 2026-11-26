import 'package:memora/presentation/notifiers/member/member_mutation_coordinator.dart';
import 'package:memora/composition_root/providers/member_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/member/member_management_state.dart';

export 'member_management_state.dart';

final memberManagementNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<MemberManagementNotifier, MemberManagementState, MemberDto>(
      MemberManagementNotifier.new,
      retry: (_, _) => null,
    );

class MemberManagementNotifier extends AsyncNotifier<MemberManagementState> {
  MemberManagementNotifier(this._currentMember);

  final MemberDto _currentMember;
  bool _isOperationInProgress = false;

  @override
  Future<MemberManagementState> build() async {
    try {
      return MemberManagementState(members: await _getMembers());
    } catch (e, stack) {
      logger.e(
        'MemberManagementNotifier.build: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<bool> refreshMembers() {
    return _runExclusiveOperation(execute: _refreshMembers);
  }

  Future<bool> createMember(MemberDto member) {
    return _runMutation(
      operationName: 'createMember',
      execute: () => ref
          .read(memberMutationCoordinatorProvider)
          .createMember(
            member,
            ownerId: _currentMember.id,
            refreshMembers: _refreshMembers,
          ),
    );
  }

  Future<bool> updateMember(MemberDto member) {
    return _runMutation(
      operationName: 'updateMember',
      execute: () => ref
          .read(memberMutationCoordinatorProvider)
          .updateMember(member, refreshMembers: _refreshMembers),
    );
  }

  Future<bool> deleteMember(String memberId, {int? expectedVersion}) {
    return _runMutation(
      operationName: 'deleteMember',
      execute: () => ref
          .read(memberMutationCoordinatorProvider)
          .deleteMember(
            memberId,
            expectedVersion: expectedVersion,
            refreshMembers: _refreshMembers,
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
            'MemberManagementNotifier.$operationName: ${e.toString()}',
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

  Future<void> _refreshMembers() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      // 読み込み失敗はbuildで記録し、AsyncErrorをViewへ通知する。
    }
  }

  Future<List<MemberDto>> _getMembers() async {
    final managedMembers = await ref
        .read(getManagedMembersUsecaseProvider)
        .execute(_currentMember);
    final refreshedCurrentMember = await ref
        .read(getMemberByIdUsecaseProvider)
        .execute(_currentMember.id);
    if (refreshedCurrentMember == null) {
      throw StateError('ログインユーザーメンバーの最新情報の取得に失敗しました');
    }

    return [refreshedCurrentMember, ...managedMembers];
  }
}
