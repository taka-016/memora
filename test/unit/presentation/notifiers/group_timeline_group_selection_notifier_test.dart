import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/member/member_dto.dart';
import 'package:memora/application/queries/group/group_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/notifiers/group_timeline_group_selection_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/test_exception.dart';
import 'group_timeline_group_selection_notifier_test.mocks.dart';

@GenerateMocks([GroupQueryService])
void main() {
  group('GroupTimelineGroupSelectionNotifier', () {
    const member = MemberDto(id: 'member-1', displayName: '太郎');
    const group = GroupDto(
      id: 'group-1',
      ownerId: 'member-1',
      name: '家族',
      members: [],
    );

    late MockGroupQueryService queryService;
    late ProviderContainer container;

    setUp(() {
      queryService = MockGroupQueryService();
      container = ProviderContainer(
        overrides: [
          groupQueryServiceProvider.overrideWithValue(queryService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('取得中から取得成功へ遷移する', () async {
      final completer = Completer<List<GroupDto>>();
      when(
        queryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) => completer.future);
      final notifier = container.read(
        groupTimelineGroupSelectionNotifierProvider.notifier,
      );

      final loadFuture = notifier.load(member);

      expect(
        container.read(groupTimelineGroupSelectionNotifierProvider).status,
        GroupTimelineGroupSelectionStatus.loading,
      );

      completer.complete([group]);
      await loadFuture;

      final state = container.read(
        groupTimelineGroupSelectionNotifierProvider,
      );
      expect(state.status, GroupTimelineGroupSelectionStatus.loaded);
      expect(state.memberId, member.id);
      expect(state.groups, [group]);
    });

    test('取得失敗時はエラー状態へ遷移する', () async {
      when(
        queryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenThrow(TestException('取得失敗'));
      final notifier = container.read(
        groupTimelineGroupSelectionNotifierProvider.notifier,
      );

      await notifier.load(member);

      final state = container.read(
        groupTimelineGroupSelectionNotifierProvider,
      );
      expect(state.status, GroupTimelineGroupSelectionStatus.error);
      expect(state.memberId, member.id);
      expect(state.message, 'エラーが発生しました');
    });

    test('新しいリクエストの後に完了した古い結果を破棄する', () async {
      const secondMember = MemberDto(id: 'member-2', displayName: '花子');
      const secondGroup = GroupDto(
        id: 'group-2',
        ownerId: 'member-2',
        name: '友人',
        members: [],
      );
      final firstCompleter = Completer<List<GroupDto>>();
      final secondCompleter = Completer<List<GroupDto>>();
      when(
        queryService.getGroupsWithMembersByMemberId(
          member.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) => firstCompleter.future);
      when(
        queryService.getGroupsWithMembersByMemberId(
          secondMember.id,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) => secondCompleter.future);
      final notifier = container.read(
        groupTimelineGroupSelectionNotifierProvider.notifier,
      );

      final firstLoad = notifier.load(member);
      final secondLoad = notifier.load(secondMember);
      secondCompleter.complete([secondGroup]);
      await secondLoad;
      firstCompleter.complete([group]);
      await firstLoad;

      final state = container.read(
        groupTimelineGroupSelectionNotifierProvider,
      );
      expect(state.memberId, secondMember.id);
      expect(state.groups, [secondGroup]);
    });
  });
}
