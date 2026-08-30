import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_group_selection_notifier.dart';
import 'package:memora/presentation/notifiers/timeline/group_timeline_refresh_notifier.dart';

void main() {
  group('GroupTimelineRefreshNotifier', () {
    const member = MemberDto(id: 'member-1', displayName: '太郎');
    const group = GroupDto(
      id: 'group-1',
      ownerId: 'member-1',
      name: '家族',
      members: [],
    );

    late _CountingGroupQueryService queryService;
    late _MutableAppClock clock;
    late ProviderContainer container;

    setUp(() {
      queryService = _CountingGroupQueryService(const [group]);
      clock = _MutableAppClock(DateTime.utc(2026, 8, 28, 12));
      container = ProviderContainer(
        overrides: [
          groupQueryServiceProvider.overrideWithValue(queryService),
          appClockProvider.overrideWithValue(clock),
        ],
      );
      container
          .read(groupTimelineGroupSelectionNotifierProvider.notifier)
          .setLoadedGroups(memberId: member.id, groups: const [group]);
    });

    tearDown(() {
      container.dispose();
    });

    test('手動更新は毎回グループ構成と年表の全行を更新する', () async {
      final firstRowsRefreshKey = container.read(timelineRowsRefreshProvider);
      final notifier = container.read(
        groupTimelineRefreshNotifierProvider.notifier,
      );

      await notifier.refreshManually(member);
      final secondRowsRefreshKey = container.read(timelineRowsRefreshProvider);
      await notifier.refreshManually(member);
      final thirdRowsRefreshKey = container.read(timelineRowsRefreshProvider);

      expect(queryService.callCount, 2);
      expect(secondRowsRefreshKey, isNot(same(firstRowsRefreshKey)));
      expect(thirdRowsRefreshKey, isNot(same(secondRowsRefreshKey)));
    });

    test('アプリ復帰が短時間に繰り返された場合は再取得を抑制する', () async {
      final notifier = container.read(
        groupTimelineRefreshNotifierProvider.notifier,
      );

      expect(await notifier.refreshOnResume(member), isTrue);
      clock.advance(const Duration(seconds: 30));
      expect(await notifier.refreshOnResume(member), isFalse);

      expect(queryService.callCount, 1);
    });

    test('抑制時間を過ぎたアプリ復帰では再取得する', () async {
      final notifier = container.read(
        groupTimelineRefreshNotifierProvider.notifier,
      );

      expect(await notifier.refreshOnResume(member), isTrue);
      clock.advance(groupTimelineResumeRefreshInterval);
      expect(await notifier.refreshOnResume(member), isTrue);

      expect(queryService.callCount, 2);
    });

    test('時刻が前回更新時刻より前に戻った場合はアプリ復帰で再取得する', () async {
      final notifier = container.read(
        groupTimelineRefreshNotifierProvider.notifier,
      );

      expect(await notifier.refreshOnResume(member), isTrue);
      clock.advance(const Duration(hours: -1));
      expect(await notifier.refreshOnResume(member), isTrue);

      expect(queryService.callCount, 2);
    });

    test('初回グループ取得中のアプリ復帰では重複して再取得しない', () async {
      container
          .read(groupTimelineGroupSelectionNotifierProvider.notifier)
          .reset();
      final notifier = container.read(
        groupTimelineRefreshNotifierProvider.notifier,
      );

      expect(await notifier.refreshOnResume(member), isFalse);

      expect(queryService.callCount, 0);
    });

    test('アプリ復帰直後でも手動更新は抑制しない', () async {
      final notifier = container.read(
        groupTimelineRefreshNotifierProvider.notifier,
      );

      expect(await notifier.refreshOnResume(member), isTrue);
      await notifier.refreshManually(member);

      expect(queryService.callCount, 2);
    });
  });
}

class _CountingGroupQueryService implements GroupQueryService {
  _CountingGroupQueryService(this.result);

  final List<GroupDto> result;
  int callCount = 0;

  @override
  Future<List<GroupDto>> getGroupsWithMembersByMemberId(
    String memberId, {
    List<OrderBy>? groupsOrderBy,
    List<OrderBy>? membersOrderBy,
  }) async {
    callCount++;
    return result;
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

class _MutableAppClock implements AppClock {
  _MutableAppClock(this._now);

  DateTime _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  @override
  DateTime now() => _now;

  @override
  Future<void> sync() async {}
}
