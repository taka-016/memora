import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/composition_root/providers/startup_common_data_providers.dart';
import 'package:memora/presentation/notifiers/startup/startup_common_data_notifier.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/core/app_logger.dart';

final groupTimelineGroupSelectionNotifierProvider =
    NotifierProvider<
      GroupTimelineGroupSelectionNotifier,
      GroupTimelineGroupSelectionState
    >(GroupTimelineGroupSelectionNotifier.new);

enum GroupTimelineGroupSelectionStatus { loading, loaded, error }

class GroupTimelineGroupSelectionState {
  const GroupTimelineGroupSelectionState({
    required this.status,
    this.memberId,
    this.groups = const [],
    this.message = '',
  });

  final GroupTimelineGroupSelectionStatus status;
  final String? memberId;
  final List<GroupDto> groups;
  final String message;
}

class GroupTimelineGroupSelectionNotifier
    extends Notifier<GroupTimelineGroupSelectionState> {
  var _requestGeneration = 0;

  @override
  GroupTimelineGroupSelectionState build() {
    return const GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loading,
    );
  }

  bool get _usesCommonData =>
      ref.read(startupCommonDataNotifierProvider.exists) &&
      ref.read(startupCommonDataOwnerProvider) != null;

  Future<List<GroupDto>> _loadGroups(
    MemberDto currentMember, {
    bool refresh = false,
  }) async {
    if (_usesCommonData) {
      final common = ref.read(startupCommonDataNotifierProvider.notifier);
      if (refresh) await common.refresh();
      return common.availableGroups();
    }
    return ref.read(getGroupsWithMembersUsecaseProvider).execute(currentMember);
  }

  Future<void> load(MemberDto currentMember) async {
    final stopwatch = Stopwatch()..start();
    if (kDebugMode) logger.i('起動データ: グループ一覧取得 開始');
    final requestGeneration = ++_requestGeneration;
    state = GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loading,
      memberId: currentMember.id,
    );

    try {
      final groups = await _loadGroups(currentMember);
      if (kDebugMode) {
        logger.i('起動データ: グループ一覧取得 完了（${stopwatch.elapsedMilliseconds}ms）');
      }
      if (requestGeneration != _requestGeneration) {
        return;
      }
      state = GroupTimelineGroupSelectionState(
        status: GroupTimelineGroupSelectionStatus.loaded,
        memberId: currentMember.id,
        groups: groups,
      );
    } catch (e, stack) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      if (e is! ApplicationValidationException) {
        logger.e(
          'GroupTimelineGroupSelectionNotifier.load: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
      }
      state = GroupTimelineGroupSelectionState(
        status: GroupTimelineGroupSelectionStatus.error,
        memberId: currentMember.id,
        message: e is ApplicationValidationException ? e.message : 'エラーが発生しました',
      );
    }
  }

  Future<void> refreshSilently(MemberDto currentMember) async {
    final requestGeneration = ++_requestGeneration;

    try {
      final groups = await _loadGroups(currentMember, refresh: true);
      if (requestGeneration != _requestGeneration) {
        return;
      }
      state = GroupTimelineGroupSelectionState(
        status: GroupTimelineGroupSelectionStatus.loaded,
        memberId: currentMember.id,
        groups: groups,
      );
    } catch (e, stack) {
      if (requestGeneration != _requestGeneration) {
        return;
      }
      logger.e(
        'GroupTimelineGroupSelectionNotifier.refreshSilently: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void setLoadedGroups({
    required String memberId,
    required List<GroupDto> groups,
  }) {
    _requestGeneration++;
    state = GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loaded,
      memberId: memberId,
      groups: groups,
    );
  }

  void setLoadError({required String memberId, required String message}) {
    _requestGeneration++;
    state = GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.error,
      memberId: memberId,
      message: message,
    );
  }

  void reset() {
    _requestGeneration++;
    state = const GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loading,
    );
  }
}
