part of 'top_page_test_support.dart';

extension TopPageAndroidWidgetTests on TopPageTestContext {
  void registerAndroidWidgetTests() {
    testWidgets('ウィジェット起動URIの確認中はグループ選択を表示しない', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier:
              _InitialUriLoadingAndroidWidgetLaunchNotifier(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
      expect(find.text('グループを選択'), findsNothing);
    });
    testWidgets('ウィジェットで指定された旅行の管理画面と編集モーダルを開く', (WidgetTester tester) async {
      final trip = TripEntryDto(
        id: 'trip-1',
        groupId: groupsWithMembers.first.id,
        year: 2025,
        name: '北海道旅行',
      );
      when(
        mockTripEntryQueryService.getTripEntryById(
          trip.id,
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => trip);
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          trip.groupId,
          trip.year,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [trip]);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: _PendingAndroidWidgetLaunchNotifier(
            trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_management')), findsOneWidget);
      expect(find.text('2025年の旅行管理'), findsNothing);
      expect(find.text('旅行編集'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      expect(
        container.read(androidWidgetLaunchNotifierProvider).pendingTripId,
        isNull,
      );
    });
    testWidgets('ウィジェット起動後に年表から戻っても年表を再表示しない', (WidgetTester tester) async {
      final singleGroup = [groupsWithMembers.first];
      final trip = TripEntryDto(
        id: 'trip-1',
        groupId: singleGroup.first.id,
        year: 2025,
        name: '北海道旅行',
      );
      when(
        mockTripEntryQueryService.getTripEntryById(
          trip.id,
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => trip);
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          trip.groupId,
          trip.year,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [trip]);
      when(
        mockGroupQueryService.getGroupsWithMembersByMemberId(
          any,
          groupsOrderBy: anyNamed('groupsOrderBy'),
          membersOrderBy: anyNamed('membersOrderBy'),
        ),
      ).thenAnswer((_) async => singleGroup);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          availableGroupsWithMembers: singleGroup,
          androidWidgetLaunchNotifier: _PendingAndroidWidgetLaunchNotifier(
            trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);

      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_timeline')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(find.text('グループ1'), findsOneWidget);
    });
    testWidgets('ウィジェットの対象年が範囲外なら年表の過去側端を表示する', (WidgetTester tester) async {
      final singleGroup = [groupsWithMembers.first];
      final targetYear = fixedNow.year - 20;
      final trip = TripEntryDto(
        id: 'trip-1',
        groupId: singleGroup.first.id,
        year: targetYear,
        name: '過去の旅行',
      );
      when(
        mockTripEntryQueryService.getTripEntryById(
          trip.id,
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => trip);
      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          trip.groupId,
          trip.year,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => [trip]);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          availableGroupsWithMembers: singleGroup,
          androidWidgetLaunchNotifier: _PendingAndroidWidgetLaunchNotifier(
            trip.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
      expect(find.textContaining('$targetYear年'), findsNothing);
      expect(find.textContaining('${fixedNow.year}年'), findsOneWidget);

      final horizontalScrollView = findTimelineHorizontalScrollView();
      final scrollController = tester
          .widget<SingleChildScrollView>(horizontalScrollView)
          .controller;
      expect(scrollController, isNotNull);
      expect(scrollController!.offset, 0);

      final preservedOffset = scrollController.position.maxScrollExtent;
      scrollController.jumpTo(preservedOffset);
      unawaited(
        TripManagementRoute(
          groupId: trip.groupId,
          year: fixedNow.year,
        ).push<void>(tester.element(find.byKey(const Key('group_timeline')))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(scrollController.offset, preservedOffset);
    });
    testWidgets('通常起動では旅行管理から戻った後も年表のスクロール位置を維持する', (
      WidgetTester tester,
    ) async {
      final singleGroup = [groupsWithMembers.first];
      await tester.pumpWidget(
        createTestWidget(availableGroupsWithMembers: singleGroup),
      );
      await tester.pumpAndSettle();

      final horizontalScrollView = findTimelineHorizontalScrollView();
      final scrollController = tester
          .widget<SingleChildScrollView>(horizontalScrollView)
          .controller!;
      scrollController.jumpTo(0);

      unawaited(
        TripManagementRoute(
          groupId: singleGroup.single.id,
          year: fixedNow.year - 1,
        ).push<void>(tester.element(find.byKey(const Key('group_timeline')))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0);
    });
    testWidgets('ウィジェットで指定された旅行がない場合は通知して通常画面へ戻る', (WidgetTester tester) async {
      when(
        mockTripEntryQueryService.getTripEntryById(
          'missing-trip',
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: _PendingAndroidWidgetLaunchNotifier(
            'missing-trip',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('指定された旅行が見つかりませんでした'), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('別のメンバーが取得したウィジェット起動結果では遷移しない', (WidgetTester tester) async {
      final staleDestination = AndroidWidgetLaunchDestination(
        memberId: 'previous-member',
        groupId: groupsWithMembers.first.id,
        year: 2025,
        tripId: 'trip-1',
        groups: groupsWithMembers,
      );

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: _ResolvedAndroidWidgetLaunchNotifier(
            staleDestination,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_management')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('ウィジェットの設定画面起動要求で設定画面を開く', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: _ResolvedAndroidWidgetLaunchNotifier(
            const AndroidWidgetSettingsLaunchDestination(memberId: 'admin1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings')), findsOneWidget);
      expect(find.byKey(const Key('group_list')), findsNothing);
    });
    testWidgets('旅行管理画面でウィジェット指定の旅行がない場合はグループ一覧へ戻る', (
      WidgetTester tester,
    ) async {
      final launchNotifier = _MutableAndroidWidgetLaunchNotifier();
      when(
        mockTripEntryQueryService.getTripEntryById(
          'missing-trip',
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: launchNotifier,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      container
          .read(appRouterConfigProvider)
          .go(
            TripManagementRoute(
              groupId: groupsWithMembers.first.id,
              year: 2025,
            ).location,
          );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trip_management')), findsOneWidget);

      launchNotifier.receiveTrip('missing-trip');
      await tester.pumpAndSettle();

      expect(find.text('指定された旅行が見つかりませんでした'), findsOneWidget);
      expect(find.byKey(const Key('trip_management')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('ウィジェット起動の解決中にDrawerを開いた場合は遅延遷移しない', (
      WidgetTester tester,
    ) async {
      final tripCompleter = Completer<TripEntryDto?>();
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) => tripCompleter.future);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: _PendingAndroidWidgetLaunchNotifier(
            'trip-1',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('hamburger_menu')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('グループ年表'), findsOneWidget);

      tripCompleter.complete(
        TripEntryDto(
          id: 'trip-1',
          groupId: groupsWithMembers.first.id,
          year: 2025,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_management')), findsNothing);
      expect(find.byKey(const Key('group_list')), findsOneWidget);
    });
    testWidgets('ウィジェット起動の解決中に通常遷移した場合は遅延遷移しない', (WidgetTester tester) async {
      final tripCompleter = Completer<TripEntryDto?>();
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) => tripCompleter.future);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: _PendingAndroidWidgetLaunchNotifier(
            'trip-1',
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      container
          .read(appRouterConfigProvider)
          .go(const SettingsRoute().location);
      await tester.pump();

      tripCompleter.complete(
        TripEntryDto(
          id: 'trip-1',
          groupId: groupsWithMembers.first.id,
          year: 2025,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings')), findsOneWidget);
      expect(find.byKey(const Key('trip_management')), findsNothing);
    });
    testWidgets('通常遷移後に届いたウィジェット起動要求は取り消さない', (WidgetTester tester) async {
      final launchNotifier = _MutableAndroidWidgetLaunchNotifier();
      final trip = TripEntryDto(
        id: 'trip-1',
        groupId: groupsWithMembers.first.id,
        year: 2025,
      );
      when(
        mockTripEntryQueryService.getTripEntryById(
          trip.id,
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) async => trip);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: launchNotifier,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      container
          .read(appRouterConfigProvider)
          .go(const SettingsRoute().location);
      launchNotifier.receiveTrip(trip.id);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('trip_management')), findsOneWidget);
    });
    testWidgets('ウィジェット起動要求の受理後に通常遷移した場合は遅延遷移しない', (WidgetTester tester) async {
      final launchNotifier = _MutableAndroidWidgetLaunchNotifier();
      final tripCompleter = Completer<TripEntryDto?>();
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) => tripCompleter.future);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: launchNotifier,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      launchNotifier.receiveTrip('trip-1');
      container
          .read(appRouterConfigProvider)
          .go(const SettingsRoute().location);
      await tester.pump();

      tripCompleter.complete(
        TripEntryDto(
          id: 'trip-1',
          groupId: groupsWithMembers.first.id,
          year: 2025,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings')), findsOneWidget);
      expect(find.byKey(const Key('trip_management')), findsNothing);
    });
    testWidgets('ウィジェット起動の解決中に同じナビ項目内で遷移した場合は遅延遷移しない', (
      WidgetTester tester,
    ) async {
      final launchNotifier = _MutableAndroidWidgetLaunchNotifier();
      final tripCompleter = Completer<TripEntryDto?>();
      when(
        mockTripEntryQueryService.getTripEntryById(
          'trip-1',
          tasksOrderBy: anyNamed('tasksOrderBy'),
          itineraryItemsOrderBy: anyNamed('itineraryItemsOrderBy'),
        ),
      ).thenAnswer((_) => tripCompleter.future);

      await tester.pumpWidget(
        createTestWidget(
          currentMember: testMember,
          androidWidgetLaunchNotifier: launchNotifier,
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TopPage)),
      );
      final router = container.read(appRouterConfigProvider);
      unawaited(
        router.push(
          TripManagementRoute(
            groupId: groupsWithMembers.first.id,
            year: 2025,
          ).location,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trip_management')), findsOneWidget);

      launchNotifier.receiveTrip('trip-1');
      await tester.pump();
      router.go(const GroupListRoute().location);
      await tester.pump();

      tripCompleter.complete(
        TripEntryDto(
          id: 'trip-1',
          groupId: groupsWithMembers.first.id,
          year: 2025,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_list')), findsOneWidget);
      expect(find.byKey(const Key('trip_management')), findsNothing);
    });
  }
}
