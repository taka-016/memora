import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_rows.dart';
import 'package:memora/presentation/features/timeline/dvc_row.dart';
import 'package:memora/presentation/features/timeline/timeline.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/trip_row.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/application/dtos/group/group_dto.dart';

class _GroupTimelineNavigationNotifierWithRefresh
    extends GroupTimelineNavigationNotifier {
  @override
  GroupTimelineNavigationState build() {
    return const GroupTimelineNavigationState(
      destination: GroupTimelineOverviewDestination(),
    );
  }
}

class _TripManagementNavigationNotifierWithRefresh
    extends GroupTimelineNavigationNotifier {
  _TripManagementNavigationNotifierWithRefresh(this.onRefresh);

  final Future<void> Function() onRefresh;

  @override
  GroupTimelineNavigationState build() {
    return GroupTimelineNavigationState(
      destination: const GroupTimelineTripManagementDestination(
        groupId: 'g1',
        year: 2024,
      ),
      timelineRowDefinitions: const [
        TripRow(groupId: 'g1', initialHeight: 40, onDestinationSelected: null),
      ],
      refreshGroupTimeline: onRefresh,
    );
  }
}

class _DvcPointCalculationNavigationNotifierWithRefresh
    extends GroupTimelineNavigationNotifier {
  _DvcPointCalculationNavigationNotifierWithRefresh(this.onRefresh);

  final Future<void> Function() onRefresh;

  @override
  GroupTimelineNavigationState build() {
    return GroupTimelineNavigationState(
      destination: const GroupTimelineDvcPointCalculationDestination(
        groupId: 'g1',
      ),
      timelineRowDefinitions: const [
        DvcRow(groupId: 'g1', initialHeight: 40, onDestinationSelected: null),
      ],
      refreshGroupTimeline: onRefresh,
    );
  }
}

class _NavigationNotifierWithCustomRows
    extends GroupTimelineNavigationNotifier {
  _NavigationNotifierWithCustomRows({
    required this.destination,
    required this.timelineRowDefinitions,
  });

  final GroupTimelineDestination destination;
  final List<TimelineRowDefinition> timelineRowDefinitions;

  @override
  GroupTimelineNavigationState build() {
    return GroupTimelineNavigationState(
      destination: destination,
      timelineRowDefinitions: timelineRowDefinitions,
    );
  }
}

class _NavigationNotifierWithInstanceAndCustomRows
    extends GroupTimelineNavigationNotifier {
  _NavigationNotifierWithInstanceAndCustomRows({
    required this.groupWithMembers,
    required this.destination,
    required this.timelineRowDefinitions,
  });

  final GroupDto groupWithMembers;
  final GroupTimelineDestination destination;
  final List<TimelineRowDefinition> timelineRowDefinitions;

  @override
  GroupTimelineNavigationState build() {
    return GroupTimelineNavigationState(
      destination: destination,
      groupTimelineInstance: Timeline(
        groupWithMembers: groupWithMembers,
        rowDefinitions: timelineRowDefinitions,
      ),
      timelineRowDefinitions: timelineRowDefinitions,
    );
  }
}

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
      expect(state.destination, const GroupTimelineGroupListDestination());
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
      expect(state.destination, const GroupTimelineGroupListDestination());
      expect(state.groupTimelineInstance, isNull);
    });

    test('グループ一覧画面へ戻ると再読込コールバックが解放される', () {
      // Arrange
      final containerWithRefresh = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            _GroupTimelineNavigationNotifierWithRefresh.new,
          ),
        ],
      );
      addTearDown(containerWithRefresh.dispose);
      final notifier = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showGroupList();

      // Assert
      final state = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(state.destination, const GroupTimelineGroupListDestination());
      expect(state.refreshGroupTimeline, isNull);
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
      expect(state.destination, const GroupTimelineOverviewDestination());
      expect(state.groupTimelineInstance, isNotNull);
    });

    test('グループ年表画面表示時に行順指定を受け取れる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      notifier.showGroupTimeline(
        testGroupWithMembers,
        rowOrder: const [
          TimelineRowType.dvc,
          TimelineRowType.trip,
          TimelineRowType.groupEvent,
          TimelineRowType.member,
        ],
      );

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.timelineRowDefinitions[0], isA<DvcRow>());
      expect(state.timelineRowDefinitions[1], isA<TripRow>());
      expect(state.timelineRowDefinitions[2].fixedColumnLabel, 'イベント');
      expect(state.timelineRowDefinitions[3].fixedColumnLabel, '花子');
    });

    test('旅行管理画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      const testGroupId = 'test-group-123';
      const testYear = 2024;
      notifier.showGroupTimeline(testGroupWithMembers);

      // Act
      notifier.showDestination(
        const GroupTimelineTripManagementDestination(
          groupId: testGroupId,
          year: testYear,
        ),
      );

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(
        state.destination,
        const GroupTimelineTripManagementDestination(
          groupId: testGroupId,
          year: testYear,
        ),
      );
    });

    test('DVCポイント計算画面に遷移できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);

      // Act
      notifier.showDestination(
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(
        state.destination,
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );
    });

    test('旅行管理画面から戻ることができる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);

      // 旅行管理画面に遷移
      notifier.showDestination(
        const GroupTimelineTripManagementDestination(
          groupId: 'test-group',
          year: 2024,
        ),
      );

      // Act
      notifier.backFromTripManagement();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.destination, const GroupTimelineOverviewDestination());
    });

    test('戻る操作で年表画面からグループ一覧画面へ戻れる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineGroupListDestination());
      expect(state.groupTimelineInstance, isNull);
    });

    test('戻る操作で年表画面を離れると再読込コールバックが解放される', () {
      // Arrange
      final containerWithRefresh = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            _GroupTimelineNavigationNotifierWithRefresh.new,
          ),
        ],
      );
      addTearDown(containerWithRefresh.dispose);
      final notifier = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineGroupListDestination());
      expect(state.refreshGroupTimeline, isNull);
    });

    test('戻る操作で旅行管理画面から年表画面へ戻れる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);
      notifier.showDestination(
        GroupTimelineTripManagementDestination(
          groupId: testGroupWithMembers.id,
          year: 2024,
        ),
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineOverviewDestination());
    });

    test('戻る操作で旅行管理画面から戻ると年表の再読込が実行される', () {
      // Arrange
      var refreshCount = 0;
      final containerWithRefresh = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _TripManagementNavigationNotifierWithRefresh(() async {
              refreshCount++;
            }),
          ),
        ],
      );
      addTearDown(containerWithRefresh.dispose);
      final notifier = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineOverviewDestination());
      expect(refreshCount, 1);
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
      expect(state.destination, const GroupTimelineGroupListDestination());
      expect(state.groupTimelineInstance, isNull);
      expect(state.refreshGroupTimeline, isNull);
    });

    test('DVCポイント計算画面から戻ることができる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);
      notifier.showDestination(
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );

      // Act
      notifier.backFromDvcPointCalculation();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.destination, const GroupTimelineOverviewDestination());
    });

    test('戻る操作でDVCポイント計算画面から年表画面へ戻れる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);
      notifier.showDestination(
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineOverviewDestination());
    });

    test('戻る操作でDVCポイント計算画面から戻ると年表の再読込が実行される', () {
      // Arrange
      var refreshCount = 0;
      final containerWithRefresh = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _DvcPointCalculationNavigationNotifierWithRefresh(() async {
              refreshCount++;
            }),
          ),
        ],
      );
      addTearDown(containerWithRefresh.dispose);
      final notifier = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = containerWithRefresh.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineOverviewDestination());
      expect(refreshCount, 1);
    });

    test('年表から離れた後に遅延した再読込コールバック登録で参照が復活しない', () async {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      notifier.showGroupTimeline(testGroupWithMembers);
      final timeline = container
          .read(groupTimelineNavigationNotifierProvider)
          .groupTimelineInstance!;

      // Act
      timeline.onSetRefreshCallback?.call(() async {});
      notifier.showGroupList();
      await Future(() {});

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.destination, const GroupTimelineGroupListDestination());
      expect(state.refreshGroupTimeline, isNull);
    });

    test('年表を再生成した直後は古い再読込コールバックが呼ばれない', () async {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );
      var oldRefreshCount = 0;
      notifier.showGroupTimeline(testGroupWithMembers);
      final firstTimeline = container
          .read(groupTimelineNavigationNotifierProvider)
          .groupTimelineInstance!;
      firstTimeline.onSetRefreshCallback?.call(() async {
        oldRefreshCount++;
      });
      await Future(() {});

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);
      notifier.showTripManagement(testGroupWithMembers.id, 2024);
      notifier.backFromTripManagement();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(state.destination, const GroupTimelineOverviewDestination());
      expect(oldRefreshCount, 0);
    });

    test('グループ一覧画面では戻る操作を処理しない', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = container.read(groupTimelineNavigationNotifierProvider);
      expect(handled, isFalse);
      expect(state.destination, const GroupTimelineGroupListDestination());
    });

    test('未定義の遷移先では戻る操作時にグループ一覧へ戻る', () {
      // Arrange
      final containerWithUnsupportedDestination = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _NavigationNotifierWithCustomRows(
              destination: const GroupTimelineTripManagementDestination(
                groupId: 'g1',
                year: 2024,
              ),
              timelineRowDefinitions: const [],
            ),
          ),
        ],
      );
      addTearDown(containerWithUnsupportedDestination.dispose);
      final notifier = containerWithUnsupportedDestination.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = containerWithUnsupportedDestination.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineGroupListDestination());
    });

    test('年表表示中の未定義の遷移先では戻る操作時に年表へ戻る', () {
      // Arrange
      final containerWithUnsupportedDestination = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _NavigationNotifierWithInstanceAndCustomRows(
              groupWithMembers: testGroupWithMembers,
              destination: const GroupTimelineTripManagementDestination(
                groupId: 'g1',
                year: 2024,
              ),
              timelineRowDefinitions: const [],
            ),
          ),
        ],
      );
      addTearDown(containerWithUnsupportedDestination.dispose);
      final notifier = containerWithUnsupportedDestination.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act
      final handled = notifier.handleBackNavigation();

      // Assert
      final state = containerWithUnsupportedDestination.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(handled, isTrue);
      expect(state.destination, const GroupTimelineOverviewDestination());
    });

    test('グループ一覧画面以外では戻る操作を処理できる', () {
      // Arrange
      final notifier = container.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Assert
      expect(notifier.canHandleBackNavigation(), isFalse);

      // Act
      notifier.showGroupTimeline(testGroupWithMembers);

      // Assert
      expect(notifier.canHandleBackNavigation(), isTrue);
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
      notifier.showDestination(
        const GroupTimelineTripManagementDestination(
          groupId: 'test-group',
          year: 2024,
        ),
      );
      expect(notifier.getStackIndex(), 2);

      // DVCポイント計算画面の場合
      notifier.showDestination(
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );
      expect(notifier.getStackIndex(), 3);
    });

    test('スタックインデックスは行定義順から動的に算出される', () {
      // Arrange
      final containerWithCustomRows = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _NavigationNotifierWithCustomRows(
              destination: const GroupTimelineTripManagementDestination(
                groupId: 'g1',
                year: 2024,
              ),
              timelineRowDefinitions: const [
                DvcRow(
                  groupId: 'g1',
                  initialHeight: 40,
                  onDestinationSelected: null,
                ),
                TripRow(
                  groupId: 'g1',
                  initialHeight: 40,
                  onDestinationSelected: null,
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(containerWithCustomRows.dispose);
      final notifier = containerWithCustomRows.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act / Assert
      expect(notifier.getStackIndex(), 3);
    });

    test('未定義の遷移先は年表未表示時にグループ一覧のインデックスへ補正される', () {
      // Arrange
      final containerWithUnsupportedDestination = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _NavigationNotifierWithCustomRows(
              destination: const GroupTimelineTripManagementDestination(
                groupId: 'g1',
                year: 2024,
              ),
              timelineRowDefinitions: const [],
            ),
          ),
        ],
      );
      addTearDown(containerWithUnsupportedDestination.dispose);
      final notifier = containerWithUnsupportedDestination.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act / Assert
      expect(notifier.getStackIndex(), 0);
    });

    test('未定義の遷移先は年表表示時に年表のインデックスへ補正される', () {
      // Arrange
      final containerWithUnsupportedDestination = ProviderContainer(
        overrides: [
          groupTimelineNavigationNotifierProvider.overrideWith(
            () => _NavigationNotifierWithInstanceAndCustomRows(
              groupWithMembers: testGroupWithMembers,
              destination: const GroupTimelineTripManagementDestination(
                groupId: 'g1',
                year: 2024,
              ),
              timelineRowDefinitions: const [],
            ),
          ),
        ],
      );
      addTearDown(containerWithUnsupportedDestination.dispose);
      final notifier = containerWithUnsupportedDestination.read(
        groupTimelineNavigationNotifierProvider.notifier,
      );

      // Act / Assert
      expect(notifier.getStackIndex(), 1);
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
      expect(state.destination, const GroupTimelineOverviewDestination());
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
      notifier.showDestination(
        const GroupTimelineTripManagementDestination(
          groupId: 'test-group',
          year: 2024,
        ),
      );
      notifier.backFromTripManagement();
      notifier.resetToGroupList();

      // Assert
      expect(notificationCount, 4);
    });
  });
}
