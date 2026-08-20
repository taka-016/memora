import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/member/create_member_usecase.dart';
import 'package:memora/application/usecases/member/delete_member_usecase.dart';
import 'package:memora/application/usecases/member/get_managed_members_usecase.dart';
import 'package:memora/application/usecases/member/get_member_by_id_usecase.dart';
import 'package:memora/application/usecases/member/update_member_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/notifiers/member_management_state.dart';

export 'member_management_state.dart';

final memberManagementNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<MemberManagementNotifier, MemberManagementState, MemberDto>(
      MemberManagementNotifier.new,
      retry: (_, _) => null,
    );

class MemberManagementNotifier extends AsyncNotifier<MemberManagementState> {
  MemberManagementNotifier(this._currentMember);

  final MemberDto _currentMember;
  bool _isMutationInProgress = false;

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

  Future<bool> refreshMembers() async {
    if (_isMutationInProgress) {
      return false;
    }

    ref.invalidateSelf();
    return true;
  }

  Future<bool> createMember(MemberDto member) {
    return _runMutation(
      operationName: 'createMember',
      execute: () => ref
          .read(createMemberUsecaseProvider)
          .execute(member, _currentMember.id),
    );
  }

  Future<bool> updateMember(MemberDto member) {
    return _runMutation(
      operationName: 'updateMember',
      execute: () => ref.read(updateMemberUsecaseProvider).execute(member),
    );
  }

  Future<bool> deleteMember(String memberId) {
    return _runMutation(
      operationName: 'deleteMember',
      execute: () => ref.read(deleteMemberUsecaseProvider).execute(memberId),
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
        'MemberManagementNotifier.$operationName: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      _isMutationInProgress = false;
      keepAliveLink.close();
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
