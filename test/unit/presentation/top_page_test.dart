import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/application/usecases/get_current_member_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/top_page.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'top_page_test.mocks.dart';

@GenerateMocks([GetGroupsWithMembersUsecase, GetCurrentMemberUseCase])
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

    return MaterialApp(
      home: TopPage(
        getGroupsWithMembersUsecase: mockUsecase,
        isTestEnvironment: true,
        getCurrentMemberUseCase:
            getCurrentMemberUseCase ?? defaultMockGetCurrentMemberUseCase,
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
      expect(find.text('トップページ'), findsOneWidget);
      expect(find.text('グループ年表'), findsOneWidget);
      expect(find.text('マップ表示'), findsOneWidget);
      expect(find.text('グループ設定'), findsOneWidget);
      expect(find.text('メンバー設定'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.group_work), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('初期状態ではトップページ画面が表示される', (WidgetTester tester) async {
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
      expect(find.text('グループ1'), findsOneWidget);
      expect(find.text('太郎'), findsOneWidget);
      expect(find.text('花子'), findsOneWidget);
      expect(find.byKey(const Key('group_member')), findsOneWidget);
    });

    testWidgets('メニューから「マップ表示」を選択すると、マップ画面が表示される', (WidgetTester tester) async {
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

      // マップ表示メニューをタップ
      await tester.tap(find.text('マップ表示'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('map_display')), findsOneWidget);
      expect(find.byKey(const Key('group_member')), findsNothing);
    });

    testWidgets('メニューから「トップページ」を選択すると、トップページ画面が表示される', (
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

      // マップ表示メニューをタップして画面切り替え
      await tester.tap(find.text('マップ表示'));
      await tester.pumpAndSettle();

      // 再度ハンバーガーメニューをタップ
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // トップページメニューをタップ
      await tester.tap(find.text('トップページ'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_member')), findsOneWidget);
      expect(find.byKey(const Key('map_display')), findsNothing);
    });

    testWidgets('メニューから「グループ年表」を選択すると、グループ年表画面が表示される', (
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
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('group_member')), findsNothing);
    });

    testWidgets('メニューから「グループ設定」を選択すると、グループ設定画面が表示される', (
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

      // グループ設定メニューをタップ
      await tester.tap(find.text('グループ設定'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_settings')), findsOneWidget);
      expect(find.byKey(const Key('group_member')), findsNothing);
    });

    testWidgets('メニューから「メンバー設定」を選択すると、メンバー設定画面が表示される', (
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

      // メンバー設定メニューをタップ
      await tester.tap(find.text('メンバー設定'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('member_settings')), findsOneWidget);
      expect(find.byKey(const Key('group_member')), findsNothing);
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
      expect(find.byKey(const Key('group_member')), findsNothing);
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

      // マップ表示メニューをタップ
      await tester.tap(find.text('マップ表示'));
      await tester.pumpAndSettle();

      // Assert - Drawerが閉じている
      expect(find.byType(Drawer), findsNothing);
    });

    testWidgets('ログインユーザーの表示名が表示される', (WidgetTester tester) async {
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
      expect(find.text('ログインユーザー'), findsOneWidget);
    });
  });
}
