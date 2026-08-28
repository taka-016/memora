import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/timeline/group_timeline_navigation_view.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';

void main() {
  test('現在のグループルートからIndexedStackのindexを決定する', () {
    expect(groupTimelineStackIndex(groupId: null), 0);
    expect(groupTimelineStackIndex(groupId: 'group-1'), 1);
  });

  testWidgets('年表表示中にアプリが復帰すると共通更新経路を実行する', (tester) async {
    final queryService = _CountingGroupQueryService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupQueryServiceProvider.overrideWithValue(queryService),
          appClockProvider.overrideWithValue(
            FixedAppClock(DateTime.utc(2026, 8, 28, 12)),
          ),
        ],
        child: const MaterialApp(
          home: GroupTimelineLifecycleObserver(
            currentMember: MemberDto(id: 'member-1', displayName: '太郎'),
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(GroupTimelineLifecycleObserver)),
    );
    container
        .read(groupTimelineGroupSelectionNotifierProvider.notifier)
        .setLoadedGroups(
          memberId: 'member-1',
          groups: const [
            GroupDto(
              id: 'group-1',
              ownerId: 'member-1',
              name: '家族',
              members: [],
            ),
          ],
        );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(queryService.callCount, 1);
  });
}

class _CountingGroupQueryService implements GroupQueryService {
  int callCount = 0;

  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    callCount++;
    return const [];
  }

  @override
  Future<GroupDto?> getGroupWithMembersById(
    String groupId, {
    List<OrderBy>? membersOrderBy,
  }) async => null;

  @override
  Future<List<GroupDto>> getManagedGroupsWithMembersByOwnerId(
    String ownerId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async => const [];
}
