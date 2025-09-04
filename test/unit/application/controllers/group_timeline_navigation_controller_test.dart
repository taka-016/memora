import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/controllers/group_timeline_navigation_controller.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';

void main() {
  group('GroupTimelineNavigationController', () {
    late ProviderContainer container;

    final testGroup = Group(
      id: 'test-group',
      administratorId: 'admin1',
      name: 'テストグループ',
    );

    final testMembers = [
      Member(
        id: 'member1',
        displayName: '山田太郎',
        kanjiFirstName: '太郎',
        kanjiLastName: '山田',
      ),
    ];

    final testGroupWithMembers = GroupWithMembers(
      group: testGroup,
      members: testMembers,
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態でグループ一覧画面が選択されている', () {
      // Act
      final state = container.read(groupTimelineNavigationControllerProvider);

      // Assert
      expect(state.currentScreen, GroupTimelineScreenState.groupList);
      expect(state.selectedGroupId, isNull);
      expect(state.selectedYear, isNull);
      expect(state.groupTimelineInstance, isNull);
      expect(state.refreshGroupTimeline, isNull);
    });

    test('グループ一覧画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );

      // Act
      notifier.showGroupList();

      // Assert
      final state = container.read(groupTimelineNavigationControllerProvider);
      expect(state.currentScreen, GroupTimelineScreenState.groupList);
      expect(state.groupTimelineInstance, isNull);
    });

    test('グループ年表画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);

      // Assert
      final state = container.read(groupTimelineNavigationControllerProvider);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
      expect(state.groupTimelineInstance, isNotNull);
    });

    test('旅行管理画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );
      const testGroupId = 'test-group-123';
      const testYear = 2024;

      // Act
      notifier.showTripManagement(testGroupId, testYear);

      // Assert
      final state = container.read(groupTimelineNavigationControllerProvider);
      expect(state.currentScreen, GroupTimelineScreenState.tripManagement);
      expect(state.selectedGroupId, testGroupId);
      expect(state.selectedYear, testYear);
    });

    test('旅行管理画面から戻ることができる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );

      // 旅行管理画面に遷移
      notifier.showTripManagement('test-group', 2024);

      // Act
      notifier.backFromTripManagement();

      // Assert
      final state = container.read(groupTimelineNavigationControllerProvider);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
      expect(state.selectedGroupId, isNull);
      expect(state.selectedYear, isNull);
    });

    test('グループ一覧にリセットできる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );

      // 年表画面に遷移（リフレッシュコールバックは自動設定される）
      notifier.showGroupTimeline(testGroupWithMembers);

      // Act
      notifier.resetToGroupList();

      // Assert
      final state = container.read(groupTimelineNavigationControllerProvider);
      expect(state.currentScreen, GroupTimelineScreenState.groupList);
      expect(state.selectedGroupId, isNull);
      expect(state.selectedYear, isNull);
      expect(state.groupTimelineInstance, isNull);
      expect(state.refreshGroupTimeline, isNull);
    });

    test('スタックインデックスを正しく取得できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );

      // グループ一覧の場合
      expect(notifier.getStackIndex(), 0);

      // 年表画面の場合
      notifier.showGroupTimeline(testGroupWithMembers);
      expect(notifier.getStackIndex(), 1);

      // 旅行管理画面の場合
      notifier.showTripManagement('test-group', 2024);
      expect(notifier.getStackIndex(), 2);
    });

    test('年表表示時にGroupTimelineインスタンスが作成される', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);

      // Assert
      final state = container.read(groupTimelineNavigationControllerProvider);
      expect(state.groupTimelineInstance, isNotNull);
      expect(state.currentScreen, GroupTimelineScreenState.timeline);
    });

    test('状態の変更が通知される', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationControllerProvider.notifier,
      );
      var notificationCount = 0;

      container.listen<GroupTimelineNavigationState>(
        groupTimelineNavigationControllerProvider,
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
