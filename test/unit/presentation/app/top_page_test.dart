import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'top_page_test.mocks.dart';
import '../../../helpers/fake_auth_manager.dart';

@GenerateMocks([
  GetGroupsWithMembersUsecase,
  GetCurrentMemberUseCase,
  AuthManager,
])
void main() {
  late MockGetGroupsWithMembersUsecase mockUsecase;

  final testMembers = [
    Member(
      id: 'member1',
      hiraganaFirstName: 'たろう',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '太郎',
      kanjiLastName: '山田',
      firstName: 'Taro',
      lastName: 'Yamada',
      displayName: '太郎',
      type: 'family',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
    ),
    Member(
      id: 'member2',
      hiraganaFirstName: 'はなこ',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '花子',
      kanjiLastName: '山田',
      firstName: 'Hanako',
      lastName: 'Yamada',
      displayName: '花子',
      type: 'family',
      birthday: DateTime(1985, 5, 10),
      gender: 'female',
    ),
  ];

  setUp(() {
    mockUsecase = MockGetGroupsWithMembersUsecase();
  });

  Widget createTestWidget({
    MockGetCurrentMemberUseCase? getCurrentMemberUseCase,
    MockAuthManager? authManager,
  }) {
    final defaultMockGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
    when(defaultMockGetCurrentMemberUseCase.execute()).thenAnswer(
      (_) async => Member(
        id: 'default_member',
        displayName: '表示名',
        kanjiLastName: 'デフォルト',
        kanjiFirstName: 'ユーザー',
      ),
    );

    return ProviderScope(
      overrides: [
        authManagerProvider.overrideWith((ref) {
          return FakeAuthManager.authenticated();
        }),
      ],
      child: MaterialApp(
        home: TopPage(
          getGroupsWithMembersUsecase: mockUsecase,
          isTestEnvironment: true,
          getCurrentMemberUseCase:
              getCurrentMemberUseCase ?? defaultMockGetCurrentMemberUseCase,
        ),
      ),
    );
  }

  group('TopPage', () {
    testWidgets('左上にハンバーガーメニューが表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byKey(const Key('hamburger_menu')), findsOneWidget);
    });

    testWidgets('メニューが表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('グループ年表'), findsOneWidget);
      expect(find.text('地図表示'), findsOneWidget);
      expect(find.text('グループ管理'), findsOneWidget);
      expect(find.text('メンバー管理'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.group_work), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('初期状態ではグループ一覧画面が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(find.byKey(const Key('map_view')), findsNothing);
    });

    testWidgets('メニューから「グループ年表」を選択すると、グループ一覧画面が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // グループ年表メニューをタップ
      await tester.tap(find.text('グループ年表'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(find.byKey(const Key('map_view')), findsNothing);
    });

    testWidgets('メニューから「地図表示」を選択すると、マップ画面が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 地図表示メニューをタップ
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('map_view')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });

    testWidgets('メニューから「メンバー管理」を選択すると、メンバー管理画面が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // メンバー管理メニューをタップ
      await tester.tap(find.text('メンバー管理'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('member_settings')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });

    testWidgets('メニューから「グループ管理」を選択すると、グループ管理画面が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // グループ管理メニューをタップ
      await tester.tap(find.text('グループ管理'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_settings')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });

    testWidgets('メニューから「設定」を選択すると、設定画面が表示される', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 設定メニューをタップ
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('settings')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });

    testWidgets('メニュー選択後にメニューが自動的に閉じる', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // 地図表示メニューをタップ
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      // Assert - Drawerが閉じている
      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('ログインユーザーのメールアドレスが表示される', (WidgetTester tester) async {
      // Arrange
      final testGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
      final currentMember = Member(
        id: 'current_member',
        displayName: 'ログインユーザー',
        kanjiLastName: '佐藤',
        kanjiFirstName: '花子',
      );

      when(
        testGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => currentMember);

      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      final widget = createTestWidget(
        getCurrentMemberUseCase: testGetCurrentMemberUseCase,
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Drawerを開く
      await tester.tap(find.byKey(const Key('hamburger_menu')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('memora'), findsWidgets);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('グループ年表から戻るボタンでグループ一覧に戻ることができる', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      final testGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
      when(
        testGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => testMembers.first);

      final widget = createTestWidget(
        getCurrentMemberUseCase: testGetCurrentMemberUseCase,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // グループ一覧からグループ選択
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // グループ年表が表示されることを確認
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('back_button')), findsOneWidget);

      // Act - 戻るボタンをタップ
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Assert - グループ一覧に戻ることを確認
      expect(find.byKey(const Key('group_timeline')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });

    testWidgets('グループ年表が遷移先から戻ったときに状態を維持している', (WidgetTester tester) async {
      // Arrange
      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      final testGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
      when(
        testGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => testMembers.first);

      final widget = createTestWidget(
        getCurrentMemberUseCase: testGetCurrentMemberUseCase,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // TopPageウィジェットを取得
      final topPageFinder = find.byType(TopPage);
      final topPageState = tester.state(topPageFinder) as dynamic;

      // 1. IndexedStackが正しくセットアップされていることを検証
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(
        indexedStack.children.length,
        3,
      ); // GroupList, GroupTimeline, TripManagement
      expect(indexedStack.index, 0); // 初期状態はGroupList（index: 0）

      // 2. 初期状態でGroupTimelineインスタンスがnullであることを検証
      expect(topPageState.groupTimelineInstanceForTest, isNull);
      expect(
        topPageState.groupTimelineStateForTest,
        GroupTimelineScreenState.groupList,
      );

      // GroupTimelineに遷移
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // 3. グループ選択後のIndexとインスタンス状態を検証
      final timelineIndexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(timelineIndexedStack.index, 1); // GroupTimeline（index: 1）
      expect(topPageState.groupTimelineInstanceForTest, isNotNull);
      expect(
        topPageState.groupTimelineStateForTest,
        GroupTimelineScreenState.timeline,
      );

      // 他画面に遷移（地図表示）
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      // 4. 他画面遷移時にGroupTimelineインスタンスがリセットされることを検証
      expect(topPageState.groupTimelineInstanceForTest, isNull);
      expect(
        topPageState.groupTimelineStateForTest,
        GroupTimelineScreenState.groupList,
      );

      // グループ年表に戻る
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('グループ年表'));
      await tester.pumpAndSettle();

      // 5. グループ年表メニューに戻った時の状態を検証
      final backToTimelineStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(backToTimelineStack.index, 0); // GroupList（index: 0）に戻る
      expect(topPageState.groupTimelineInstanceForTest, isNull);
      expect(
        topPageState.groupTimelineStateForTest,
        GroupTimelineScreenState.groupList,
      );

      // 再度同じグループを選択
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // 6. 再選択時の状態を検証
      final finalIndexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(finalIndexedStack.index, 1); // GroupTimeline（index: 1）
      expect(topPageState.groupTimelineInstanceForTest, isNotNull);
      expect(
        topPageState.groupTimelineStateForTest,
        GroupTimelineScreenState.timeline,
      );
    });

    testWidgets('旅行管理から戻った時にリフレッシュコールバックが呼び出される', (tester) async {
      // Arrange
      bool refreshCallbackCalled = false;

      final groupsWithMembers = [
        GroupWithMembers(
          group: Group(id: '1', administratorId: 'admin1', name: 'グループ1'),
          members: testMembers,
        ),
      ];
      when(mockUsecase.execute(any)).thenAnswer((_) async => groupsWithMembers);

      final widget = createTestWidget();

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // TopPageの状態を取得
      final topPageFinder = find.byType(TopPage);
      final topPageState = tester.state(topPageFinder) as dynamic;

      // グループを選択してタイムライン表示
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // モック用のリフレッシュ関数を設定
      void mockRefreshFunction() => refreshCallbackCalled = true;
      topPageState.refreshGroupTimelineForTest = mockRefreshFunction;

      // Act - 旅行管理から戻る動作をシミュレート
      topPageState.onBackFromTripManagementForTest();
      await tester.pumpAndSettle();

      // Assert - リフレッシュコールバックが呼び出されたことを確認
      expect(refreshCallbackCalled, isTrue);
    });
  });
}
