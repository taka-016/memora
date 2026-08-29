part of 'top_page_test_support.dart';

extension TopPageBackNavigationTests on TopPageTestContext {
  void registerBackNavigationTests() {
    testWidgets('DVCポイント計算画面の戻るボタンを押すとグループ年表に戻る', (WidgetTester tester) async {
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

      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();
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

      // Act: 戻る
      await tester.tap(find.byKey(const Key('dvc_back_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byKey(const Key('dvc_point_calculation_screen')),
        findsNothing,
      );
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
    });
    testWidgets('グループ年表から戻るボタンでグループ一覧に戻ることができる', (WidgetTester tester) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => singleGroup);
      when(
        mockMemberQueryService.getMemberByAccountId(any),
      ).thenAnswer((_) async => testMember);

      final widget = createTestWidget(availableGroupsWithMembers: singleGroup);

      await tester.pumpWidget(widget);
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
      expect(find.text('グループ1'), findsOneWidget);
    });
    testWidgets('手動更新後に戻るボタンを押すと1件だけのグループ一覧へ戻る', (WidgetTester tester) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      final widget = createTestWidget(availableGroupsWithMembers: singleGroup);
      stubFreshGroupsWithMembers(singleGroup);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const Key('timeline_refresh_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('アプリ復帰更新後に戻るボタンを押すと1件だけのグループ一覧へ戻る', (
      WidgetTester tester,
    ) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      final widget = createTestWidget(availableGroupsWithMembers: singleGroup);
      stubFreshGroupsWithMembers(singleGroup);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      // Act
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('Androidの戻る操作でグループ年表からグループ一覧に戻る', (WidgetTester tester) async {
      // Arrange
      final singleGroup = [groupsWithMembers.first];
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => singleGroup);

      await tester.pumpWidget(
        createTestWidget(availableGroupsWithMembers: singleGroup),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      // Act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('Androidの戻る操作で旅行管理画面からグループ年表に戻る', (WidgetTester tester) async {
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

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      container
          .read(appRouterConfigProvider)
          .go(
            TripManagementRoute(
              groupId: groupsWithMembers.first.id,
              year: 2024,
            ).location,
          );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trip_management')), findsOneWidget);

      // Act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('trip_management')), findsNothing);
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
    });
    testWidgets('旅行管理画面から戻っただけでは年表の全行を再取得しない', (WidgetTester tester) async {
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

      await tester.tap(find.byKey(const Key('scrollable_row_0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trip_management')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      verify(
        mockGroupEventQueryService.getGroupEventsByGroupId(
          groupsWithMembers.first.id,
          orderBy: anyNamed('orderBy'),
        ),
      ).called(1);
    });
    testWidgets('Androidの戻る操作でDVCポイント計算画面からグループ年表に戻る', (
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

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dvc_point_calculation_screen')),
        findsOneWidget,
      );

      // Act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byKey(const Key('dvc_point_calculation_screen')),
        findsNothing,
      );
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
    });
    testWidgets('Drawer表示中のAndroid戻る操作はDrawerを閉じて年表画面を維持する', (
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

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsOneWidget);

      // Act
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Drawer), findsNothing);
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });
    testWidgets('メニューから遷移した各画面でAndroidの戻る操作を行うとグループ年表に戻る', (
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

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('グループ1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      final menuTargets = <({String label, Finder finder})>[
        (label: '地図表示', finder: find.byKey(const Key('map_view'))),
        (label: 'グループ管理', finder: find.byKey(const Key('group_settings'))),
        (label: 'メンバー管理', finder: find.byKey(const Key('member_settings'))),
        (label: '設定', finder: find.byKey(const Key('settings'))),
        (label: 'アカウント設定', finder: find.text('アカウント設定')),
      ];

      for (final target in menuTargets) {
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(target.label));
        await tester.pumpAndSettle();

        if (target.label == '地図表示') {
          expect(find.byKey(const Key('map_group_list')), findsOneWidget);
          await tester.tap(find.text('グループ1'));
          await tester.pumpAndSettle();
        }

        expect(target.finder, findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('group_timeline')), findsOneWidget);
        expect(target.finder, findsNothing);
      }
    });
    testWidgets('選択中のDrawer画面を再度選んでも同じルートを重複して積まない', (
      WidgetTester tester,
    ) async {
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
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('map_view')), findsNothing);
    });
    testWidgets('Drawerのトップレベル画面を切り替えた後の戻る操作で年表に戻る', (
      WidgetTester tester,
    ) async {
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
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('地図表示'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.byKey(const Key('map_view')), findsNothing);
      expect(find.byKey(const Key('settings')), findsNothing);
    });
  }
}
