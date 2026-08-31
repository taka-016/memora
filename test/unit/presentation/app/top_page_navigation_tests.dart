part of 'top_page_test_support.dart';

extension TopPageNavigationTests on TopPageTestContext {
  void registerNavigationTests() {
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
    testWidgets('選択グループを取得中でも詳細画面状態ならクラッシュしない', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          initialLocation: const TripManagementRoute(
            groupId: 'g1',
            year: 2024,
          ).location,
        ),
      );

      // Assert
      expect(tester.takeException(), isNull);
    });
    testWidgets('所属グループの確認中はDVC詳細のデータを取得しない', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialLocation: const DvcPointCalculationRoute(
            groupId: 'unverified-group',
          ).location,
          groupSelectionNotifier: _PendingGroupSelectionNotifier(),
        ),
      );
      await tester.pump();

      verifyNever(
        mockDvcPointContractQueryService.getDvcPointContractsByGroupId(
          any,
          orderBy: anyNamed('orderBy'),
        ),
      );
      verifyNever(
        mockDvcLimitedPointQueryService.getDvcLimitedPointsByGroupId(
          any,
          orderBy: anyNamed('orderBy'),
        ),
      );
      verifyNever(
        mockDvcPointUsageQueryService.getDvcPointUsagesByGroupId(
          any,
          orderBy: anyNamed('orderBy'),
        ),
      );
    });
    testWidgets('所属グループの確認中は旅行管理のデータを取得しない', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          initialLocation: const TripManagementRoute(
            groupId: 'unverified-group',
            year: 2026,
          ).location,
          groupSelectionNotifier: _PendingGroupSelectionNotifier(),
        ),
      );
      await tester.pump();

      verifyNever(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          any,
          any,
          orderBy: anyNamed('orderBy'),
        ),
      );
    });
    testWidgets('詳細ルートの所属グループ取得に失敗した場合は再読み込みできる', (tester) async {
      final groupSelectionNotifier = _ErrorGroupSelectionNotifier(
        'default_member',
      );
      await tester.pumpWidget(
        createTestWidget(
          initialLocation: const TripManagementRoute(
            groupId: 'unverified-group',
            year: 2026,
          ).location,
          groupSelectionNotifier: groupSelectionNotifier,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('再読み込み'), findsOneWidget);

      await tester.tap(find.text('再読み込み'));
      await tester.pump();

      expect(groupSelectionNotifier.loadCalled, isTrue);
    });
    testWidgets('所属グループが1件のみなら初回表示でグループ年表を直接開く', (WidgetTester tester) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => singleGroup);

      // Act
      await tester.pumpWidget(
        createTestWidget(availableGroupsWithMembers: singleGroup),
      );
      await tester.pump();

      expect(find.byKey(const Key('group_list')), findsNothing);

      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });
    testWidgets('グループ年表表示時はメンバーイベントもテスト用QueryServiceから取得する', (
      WidgetTester tester,
    ) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => singleGroup);

      // Act
      await tester.pumpWidget(
        createTestWidget(availableGroupsWithMembers: singleGroup),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockMemberEventQueryService.getMemberEventsByMemberIds(
          any,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(greaterThan(0));
    });
    testWidgets('所属グループが1件のみならメニューから開いてもグループ年表を直接開く', (
      WidgetTester tester,
    ) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => singleGroup);

      // Act
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('グループ年表'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });
    testWidgets('メニューから地図表示を選択すると、グループ選択後に対象地図を表示する', (
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

      // 地図表示メニューをタップ
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map_group_list')), findsOneWidget);
      expect(find.byKey(const Key('map_view')), findsNothing);

      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('map_view')), findsOneWidget);
      expect(find.byKey(const Key('map_group_list')), findsNothing);
    });
    testWidgets('グループ年表の「DVCポイント利用」の編集をタップすると計算画面に遷移する', (
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

      // グループ一覧からグループ選択して年表へ遷移する
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      // 年表画面のDVCポイント利用編集ボタンを押下する
      await tester.tap(
        find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byKey(const Key('dvc_point_calculation_screen')),
        findsOneWidget,
      );
      expect(find.text('グループ1'), findsOneWidget);
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
      final currentMember = MemberDto(
        id: 'current_member',
        displayName: 'ログインユーザー',
        kanjiLastName: '佐藤',
        kanjiFirstName: '花子',
      );

      when(mockMemberQueryService.getMemberByAccountId(any))
          .thenAnswer((_) async => currentMember);
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
    testWidgets('存在しないグループIDを指定するとグループ一覧へ戻る', (WidgetTester tester) async {
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      await tester.pumpWidget(
        createTestWidget(
          initialLocation: const GroupTimelineRoute(groupId: 'missing-group')
              .location,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      expect(
        container.read(appRouterConfigProvider).state.matchedLocation,
        const GroupListRoute().location,
      );
      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(find.text('指定されたグループが見つかりませんでした'), findsOneWidget);
    });
    testWidgets('別画面からメニューでグループ年表を開き直すとグループ一覧から再開する', (
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
      when(mockMemberQueryService.getMemberByAccountId(any))
          .thenAnswer((_) async => testMember);

      final widget = createTestWidget();

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      final router = container.read(appRouterConfigProvider);

      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(router.state.matchedLocation, const GroupListRoute().location);

      // GroupTimelineに遷移
      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(
        router.state.matchedLocation,
        GroupTimelineRoute(groupId: groupsWithMembers.first.id).location,
      );

      // 他画面に遷移（地図表示）
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, const MapRoute().location);

      // グループ年表に戻る
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('グループ年表'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, const GroupListRoute().location);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(find.byKey(const Key('group_timeline')), findsNothing);
    });
    testWidgets('グループ年表表示中に同じメニューを再タップしても状態を維持する', (WidgetTester tester) async {
      // Arrange
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      // Act
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('グループ年表'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
      verify(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).called(1);
    });
    testWidgets('初期フレーム後もRouterで指定したナビゲーション状態を維持する', (
      WidgetTester tester,
    ) async {
      // Arrange
      final defaultMember = MemberDto(
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

      when(mockMemberQueryService.getMemberByAccountId(any))
          .thenAnswer((_) async => defaultMember);
      when(mockAuthService.getCurrentUser()).thenAnswer((_) async => testUser);
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => groupsWithMembers);

      final initialRoute = TripManagementRoute(
        groupId: groupsWithMembers.first.id,
        year: 2024,
      );
      final widget = createTestWidget(
        memberQueryService: mockMemberQueryService,
        authService: mockAuthService,
        currentMember: defaultMember,
        initialLocation: initialRoute.location,
      );

      // Act
      await tester.pumpWidget(widget); // 初期フレーム
      await tester.pump(); // post frame callback を実行

      final topPageElement = tester.element(find.byType(TopPage));
      final container = ProviderScope.containerOf(topPageElement);

      expect(
        container.read(appRouterConfigProvider).state.matchedLocation,
        initialRoute.location,
      );
      expect(find.byKey(const Key('trip_management')), findsOneWidget);
    });
  }
}
