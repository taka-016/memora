import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/application/managers/auth_manager.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/domain/entities/user.dart';
import 'package:memora/domain/entities/auth_state.dart';
import 'package:memora/presentation/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'top_page_test.mocks.dart';

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

    final defaultMockAuthManager = MockAuthManager();
    when(defaultMockAuthManager.state).thenReturn(
      AuthState.authenticated(
        const User(
          id: 'test_user_id',
          loginId: 'test@example.com',
          isVerified: true,
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthManager>.value(
          value: authManager ?? defaultMockAuthManager,
        ),
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

    testWidgets('ハンバーガーメニューをタップするとDrawerが開く', (WidgetTester tester) async {
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
      expect(find.byType(Drawer), findsOneWidget);
    });

    testWidgets('Drawerにメニューアイテムが表示される', (WidgetTester tester) async {
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
      expect(find.text('グループ一覧'), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('2人のメンバー'), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
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
      expect(find.byKey(const Key('map_display')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
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
      expect(find.byKey(const Key('map_display')), findsNothing);
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

    testWidgets('メニュー選択後にDrawerが自動的に閉じる', (WidgetTester tester) async {
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

    testWidgets('GroupTimelineインスタンスの再利用動作が正しく実装されている', (
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

      final testGetCurrentMemberUseCase = MockGetCurrentMemberUseCase();
      when(
        testGetCurrentMemberUseCase.execute(),
      ).thenAnswer((_) async => testMembers.first);

      final widget = createTestWidget(
        getCurrentMemberUseCase: testGetCurrentMemberUseCase,
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // グループ一覧からGroupTimelineに遷移
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // GroupTimelineが表示されることを確認
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      // 他の画面に遷移してから戻ってもGroupTimelineが表示される
      // （インスタンス再利用の実装があるため、これが正常に動作する）

      // グループ年表以外のメニューを選択
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('map_display')), findsOneWidget);

      // 再度グループ年表メニューを選択
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('グループ年表'));
      await tester.pumpAndSettle();

      // グループ一覧に戻る（インスタンスクリア）
      expect(find.byKey(const Key('group_list')), findsOneWidget);

      // 再度同じグループを選択
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      // この時点で新しいGroupTimelineインスタンスが作成されている
      // （実装により、グループ一覧からの遷移は毎回新インスタンス）
    });
  });
}
