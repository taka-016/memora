import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

void main() {
  group('GroupTimelineNavigationNotifier', () {
    late ProviderContainer container;
    late GroupDto testGroupWithMembers;

    setUp(() {
      container = ProviderContainer();
      testGroupWithMembers = GroupDto(
        id: '1',
        ownerId: 'owner1',
        name: 'テストグループ',
        members: [
          GroupMemberDto(
            memberId: 'member1',
            groupId: 'group1',
            displayName: '花子',
            email: 'hanako@example.com',
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態でグループ一覧画面が選択されている', () {
      // Act
      final state = container.read(groupTimelineNavigationNotifierProvider);

      // Assert
      expect(state.currentScreen, GroupTimelineScreenState.groupList);
      expect(state.selectedGroupId, isNull);
      expect(state.selectedYear, isNull);
      expect(state.selectedDvcGroup, isNull);
      expect(state.groupTimelineInstance, isNull);
      expect(state.refreshGroupTimeline, isNull);
    });

    test('グループ一覧画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showGroupList();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.groupList);
      expect(state.groupTimelineInstance, isNull);
    });

    test('グループ年表画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
      expect(state.groupTimelineInstance, isNotNull);
    });

    test('旅行管理画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      const testGroupId = 'test-group-123';
      const testYear = 2024;

      // Act
      notifier.showTripManagement(testGroupId, testYear);

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.tripManagement);
      expect(state.selectedGroupId, testGroupId);
      expect(state.selectedYear, testYear);
    });

    test('DVCポイント計算画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showDvcPointCalculation(testGroupWithMembers);

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.dvcPointCalculation);
      expect(state.selectedDvcGroup, testGroupWithMembers);
    });

    test('旅行管理画面から戻ることができる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // 旅行管理画面に遷移
      notifier.showTripManagement('test-group', 2024);

      // Act
      notifier.backFromTripManagement();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
      expect(state.selectedGroupId, isNull);
      expect(state.selectedYear, isNull);
    });

    test('グループ一覧にリセットできる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // 年表画面に遷移（リフレッシュコールバックは自動設定される）
      notifier.showGroupTimeline(testGroupWithMembers);

      // Act
      notifier.resetToGroupList();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.groupList);
      expect(state.selectedGroupId, isNull);
      expect(state.selectedYear, isNull);
      expect(state.selectedDvcGroup, isNull);
      expect(state.groupTimelineInstance, isNull);
      expect(state.refreshGroupTimeline, isNull);
    });

    test('DVCポイント計算画面から戻ることができる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);
      notifier.showDvcPointCalculation(testGroupWithMembers);

      // Act
      notifier.backFromDvcPointCalculation();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
      expect(state.selectedDvcGroup, isNull);
    });

    test('スタックインデックスを正しく取得できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // グループ一覧の場合
      expect(notifier.getStackIndex(), 0);

      // 年表画面の場合
      notifier.showGroupTimeline(testGroupWithMembers);
      expect(notifier.getStackIndex(), 1);

      // 旅行管理画面の場合
      notifier.showTripManagement('test-group', 2024);
      expect(notifier.getStackIndex(), 2);

      // DVCポイント計算画面の場合
      notifier.showDvcPointCalculation(testGroupWithMembers);
      expect(notifier.getStackIndex(), 3);
    });

    test('年表表示時にGroupTimelineインスタンスが作成される', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.groupTimelineInstance, isNotNull);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
    });

    test('状態の変更が通知される', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      var notificationCount = 0;

      container.listen<GroupTimelineNavigationState>(
        groupTimelineNavigationNotifierProvider,
        (previous, next) {
          notificationCount++;
        },
      );

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);
      notifier.showTripManagement('test-group', 2024);
      notifier.backFromTripManagement();
      notifier.resetToGroupList();

      // Assert
      expect(notificationCount, 4);
    });
  });
}
