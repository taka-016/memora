import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/usecases/group/get_groups_with_members_usecase.dart';
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

  Future<void> load(MemberDto currentMember) async {
    final requestGeneration = ++_requestGeneration;
    state = GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loading,
      memberId: currentMember.id,
    );

    try {
      final groups = await ref
          .read(getGroupsWithMembersUsecaseProvider)
          .execute(currentMember);
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
        'GroupTimelineGroupSelectionNotifier.load: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      state = GroupTimelineGroupSelectionState(
        status: GroupTimelineGroupSelectionStatus.error,
        memberId: currentMember.id,
        message: 'エラーが発生しました',
      );
    }
  }

  Future<void> refreshSilently(MemberDto currentMember) async {
    final requestGeneration = ++_requestGeneration;

    try {
      final groups = await ref
          .read(getGroupsWithMembersUsecaseProvider)
          .execute(currentMember);
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

  void reset() {
    _requestGeneration++;
    state = const GroupTimelineGroupSelectionState(
      status: GroupTimelineGroupSelectionStatus.loading,
    );
  }
}
