import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';

const groupTimelineResumeRefreshInterval = Duration(minutes: 1);

final groupTimelineRefreshNotifierProvider =
    NotifierProvider<GroupTimelineRefreshNotifier, GroupTimelineRefreshState>(
      GroupTimelineRefreshNotifier.new,
    );

class GroupTimelineRefreshState {
  const GroupTimelineRefreshState({this.lastRefreshAt});

  final DateTime? lastRefreshAt;
}

class GroupTimelineRefreshNotifier extends Notifier<GroupTimelineRefreshState> {
  @override
  GroupTimelineRefreshState build() {
    return const GroupTimelineRefreshState();
  }

  Future<void> refreshManually(MemberDto currentMember) async {
    await _refresh(currentMember);
  }

  Future<bool> refreshOnResume(MemberDto currentMember) async {
    final groupSelectionState = ref.read(
      groupTimelineGroupSelectionNotifierProvider,
    );
    if (groupSelectionState.status ==
        GroupTimelineGroupSelectionStatus.loading) {
      return false;
    }

    final now = ref.read(appClockProvider).now();
    if (_shouldSuppressResumeRefresh(now)) {
      return false;
    }

    await _refresh(currentMember, refreshedAt: now);
    return true;
  }

  bool _shouldSuppressResumeRefresh(DateTime now) {
    final lastRefreshAt = state.lastRefreshAt;
    if (lastRefreshAt == null) {
      return false;
    }

    final elapsed = now.difference(lastRefreshAt);
    return !elapsed.isNegative && elapsed < groupTimelineResumeRefreshInterval;
  }

  Future<void> _refresh(
    MemberDto currentMember, {
    DateTime? refreshedAt,
  }) async {
    state = GroupTimelineRefreshState(
      lastRefreshAt: refreshedAt ?? ref.read(appClockProvider).now(),
    );
    await ref
        .read(groupTimelineGroupSelectionNotifierProvider.notifier)
        .refreshSilently(currentMember);
    ref.invalidate(timelineRowsRefreshProvider);
  }
}
