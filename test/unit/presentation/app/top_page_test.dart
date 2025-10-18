import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/domain/value_objects/auth_state.dart';
import 'package:memora/presentation/notifiers/auth_notifier.dart';
import 'package:memora/presentation/notifiers/group_timeline_navigation_notifier.dart';
import 'package:memora/presentation/notifiers/navigation_notifier.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/repositories/member_repository.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/dtos/group/group_with_members_dto.dart';
import 'package:memora/presentation/app/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'top_page_test.mocks.dart';
import '../../../helpers/fake_auth_notifier.dart';
import '../../../helpers/test_exception.dart';

// テスト用の初期状態を持つNotifier（TopPageのpostFrameでのリセット検証用）
class _TestNavigationNotifier extends NavigationNotifier {
  _TestNavigationNotifier() : super() {
    state = const NavigationState(selectedItem: NavigationItem.settings);
  }
}

class _TestGroupTimelineNavigationNotifier
    extends GroupTimelineNavigationNotifier {
  _TestGroupTimelineNavigationNotifier() : super() {
    state = const GroupTimelineNavigationState(
      currentScreen: GroupTimelineScreenState.timeline,
      selectedGroupId: 'g1',
      selectedYear: 2024,
    );
  }
}

@GenerateMocks([
  GroupQueryService,
  MemberRepository,
  AuthService,
  AuthNotifier,
  PinQueryService,
])
void main() {
  late MockGroupQueryService mockGroupQueryService;
  late MockMemberRepository mockMemberRepository;
  late MockAuthService mockAuthService;
  late MockPinQueryService mockPinQueryService;
  late List<GroupWithMembersDto> groupsWithMembers;
  late Member testMember;

  setUp(() {
    mockGroupQueryService = MockGroupQueryService();
    mockMemberRepository = MockMemberRepository();
    mockAuthService = MockAuthService();
    mockPinQueryService = MockPinQueryService();

    when(
      mockPinQueryService.getPinsByMemberId(any),
    ).thenAnswer((_) async => []);

    testMember = Member(
      id: 'admin1',
      hiraganaFirstName: 'たろう',
      hiraganaLastName: 'やまだ',
      kanjiFirstName: '太郎',
      kanjiLastName: '山田',
      firstName: 'Taro',
      lastName: 'Yamada',
      displayName: 'タロちゃん',
      type: 'family',
      birthday: DateTime(1990, 1, 1),
      gender: 'male',
    );

    groupsWithMembers = [
      GroupWithMembersDto(
        id: '1',
        ownerId: 'owner1',
        name: 'グループ1',
        members: [
          GroupMemberDto(
            memberId: 'member1',
            groupId: 'group1',
            displayName: '太郎',
            email: 'taro@example.com',
          ),
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group2',
            displayName: '花子',
            email: 'hanako@example.com',
          ),
        ],
      ),
    ];
  });

  Widget createTestWidget({
    MockMemberRepository? memberRepository,
    MockAuthService? authService,
    MockAuthNotifier? authNotifier,
  }) {
    final defaultMember = Member(
      id: 'default_member',
      displayName: '表示名',
      kanjiLastName: 'デフォルト',
      kanjiFirstName: 'ユーザー',
    );

    final testMemberRepository = memberRepository ?? mockMemberRepository;
    final testAuthService = authService ?? mockAuthService;

    const testUser = User(
      id: 'test_user_id',
      loginId: 'test@example.com',
      isVerified: true,
    );

    when(
      testMemberRepository.getMemberByAccountId(any),
    ).thenAnswer((_) async => defaultMember);
    when(testAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
    when(
      mockGroupQueryService.getGroupsWithMembersByMemberId(
        any,
        groupsOrderBy: anyNamed('groupsOrderBy'),
        membersOrderBy: anyNamed('membersOrderBy'),
      ),
    ).thenAnswer((_) async => groupsWithMembers);

    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith((ref) {
          return FakeAuthNotifier.authenticated();
        }),
        memberRepositoryProvider.overrideWithValue(testMemberRepository),
        authServiceProvider.overrideWithValue(testAuthService),
        groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
        pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
      ],
      child: MaterialApp(home: TopPage(isTestEnvironment: true)),
    );
  }

  group('TopPage', () {
    testWidgets('左上にハンバーガーメニューが表示される', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byKey(const Key('hamburger_menu')), findsOneWidget);
    });

    testWidgets('メニューが表示される', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

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
      final currentMember = Member(
        id: 'current_member',
        displayName: 'ログインユーザー',
        kanjiLastName: '佐藤',
        kanjiFirstName: '花子',
      );

      when(
        mockMemberRepository.getMemberByAccountId(any),
      ).thenAnswer((_) async => currentMember);
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      final widget = createTestWidget();

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);
      when(
        mockMemberRepository.getMemberByAccountId(any),
      ).thenAnswer((_) async => testMember);

      final widget = createTestWidget();

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
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);
      when(
        mockMemberRepository.getMemberByAccountId(any),
      ).thenAnswer((_) async => testMember);

      final widget = createTestWidget();

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // TopPageウィジェットを取得
      final topPageFinder = find.byType(TopPage);

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
      final container = ProviderScope.containerOf(
        tester.element(topPageFinder),
      );
      expect(
        container
            .read(groupTimelineNavigationNotifierProvider)
            .groupTimelineInstance,
        isNull,
      );
      expect(
        container.read(groupTimelineNavigationNotifierProvider).currentScreen,
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
      expect(
        container
            .read(groupTimelineNavigationNotifierProvider)
            .groupTimelineInstance,
        isNotNull,
      );
      expect(
        container.read(groupTimelineNavigationNotifierProvider).currentScreen,
        GroupTimelineScreenState.timeline,
      );

      // 他画面に遷移（地図表示）
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      // 4. 他画面遷移時にGroupTimelineインスタンスがリセットされることを検証
      expect(
        container
            .read(groupTimelineNavigationNotifierProvider)
            .groupTimelineInstance,
        isNull,
      );
      expect(
        container.read(groupTimelineNavigationNotifierProvider).currentScreen,
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
      expect(
        container
            .read(groupTimelineNavigationNotifierProvider)
            .groupTimelineInstance,
        isNull,
      );
      expect(
        container.read(groupTimelineNavigationNotifierProvider).currentScreen,
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
      expect(
        container
            .read(groupTimelineNavigationNotifierProvider)
            .groupTimelineInstance,
        isNotNull,
      );
      expect(
        container.read(groupTimelineNavigationNotifierProvider).currentScreen,
        GroupTimelineScreenState.timeline,
      );
    });

    testWidgets('初期フレーム後にナビゲーションとタイムラインがリセットされる', (WidgetTester tester) async {
      // Arrange
      final defaultMember = Member(
        id: 'default_member',
        displayName: '表示名',
        kanjiLastName: 'デフォルト',
        kanjiFirstName: 'ユーザー',
      );
      const testUser = User(
        id: 'test_user_id',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockMemberRepository.getMemberByAccountId(any),
      ).thenAnswer((_) async => defaultMember);
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      // Providerをオーバーライドして、非デフォルト状態から開始
      final widget = ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) {
            return FakeAuthNotifier.authenticated();
          }),
          navigationNotifierProvider.overrideWith((ref) {
            return _TestNavigationNotifier();
          }),
          groupTimelineNavigationNotifierProvider.overrideWith((ref) {
            return _TestGroupTimelineNavigationNotifier();
          }),
          memberRepositoryProvider.overrideWithValue(mockMemberRepository),
          authServiceProvider.overrideWithValue(mockAuthService),
          groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
          pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
        ],
        child: MaterialApp(home: TopPage(isTestEnvironment: true)),
      );

      // Act
      await tester.pumpWidget(widget); // 初期フレーム
      await tester.pump(); // post frame callback を実行

      // Providerの状態を取得
      final topPageElement = tester.element(find.byType(TopPage));
      final container = ProviderScope.containerOf(topPageElement);

      // Assert - TopPageのpost frame処理でリセットされていること
      final navState = container.read(navigationNotifierProvider);
      expect(navState.selectedItem, NavigationItem.groupTimeline);

      final timelineState = container.read(
        groupTimelineNavigationNotifierProvider,
      );
      expect(timelineState.currentScreen, GroupTimelineScreenState.groupList);
      expect(timelineState.selectedGroupId, isNull);
      expect(timelineState.selectedYear, isNull);
    });

    testWidgets('_currentMember取得でエラーになった場合、SnackBarでエラーを表示してログアウトする', (
      WidgetTester tester,
    ) async {
      // Arrange
      const testUser = User(
        id: 'test_user_id',
        loginId: 'test@example.com',
        isVerified: true,
      );

      when(
        mockMemberRepository.getMemberByAccountId(any),
      ).thenThrow(TestException('メンバー情報の取得に失敗しました'));
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      final fakeAuthNotifier = FakeAuthNotifier(
        const AuthState.authenticated(testUser),
      );
      final widget = ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => fakeAuthNotifier),
          memberRepositoryProvider.overrideWithValue(mockMemberRepository),
          authServiceProvider.overrideWithValue(mockAuthService),
          groupQueryServiceProvider.overrideWithValue(mockGroupQueryService),
          pinQueryServiceProvider.overrideWithValue(mockPinQueryService),
        ],
        child: MaterialApp(home: TopPage(isTestEnvironment: true)),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('メンバー情報の取得に失敗しました。再度ログインしてください。'), findsOneWidget);
      expect(fakeAuthNotifier.logoutCalled, isTrue);
    });
  });
}
