import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/group/group_event_query_service.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/domain/entities/group/group_event.dart';
import 'package:memora/domain/repositories/group/group_event_repository.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:memora/presentation/features/timeline/timeline_controller.dart';
import 'package:memora/presentation/features/timeline/timeline_rows.dart';
import 'package:memora/presentation/features/timeline/timeline.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/timeline_row_definition.dart';
import 'package:memora/presentation/notifiers/group_timeline_destination.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'group_timeline_test.mocks.dart';

@GenerateMocks([TripEntryQueryService])
void main() {
  late GroupDto testGroupWithMembers;
  late MockTripEntryQueryService mockTripEntryQueryService;
  late DvcPointUsageQueryService dvcPointUsageQueryService;
  late GroupEventQueryService groupEventQueryService;
  late _FakeGroupEventRepository groupEventRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testGroupWithMembers = GroupDto(
      id: '1',
      ownerId: 'owner1',
      name: 'テストグループ',
      members: [
        GroupMemberDto(
          memberId: 'member1',
          groupId: 'group1',
          displayName: 'タロちゃん',
          email: 'taro@example.com',
        ),
      ],
    );

    mockTripEntryQueryService = MockTripEntryQueryService();
    dvcPointUsageQueryService = const _FakeDvcPointUsageQueryService([]);
    groupEventQueryService = const _FakeGroupEventQueryService([]);
    groupEventRepository = _FakeGroupEventRepository();

    // デフォルトの挙動を設定
    when(
      mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
        any,
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget createTestWidget({
    GroupDto? groupWithMembers,
    TripEntryQueryService? tripEntryQueryService,
    DvcPointUsageQueryService? dvcPointUsageService,
    GroupEventQueryService? groupEventService,
    GroupEventRepository? groupEventRepo,
    VoidCallback? onBackPressed,
    void Function(RefreshTimelineCallback)? onSetRefreshCallback,
    ValueChanged<GroupTimelineDestination>? onDestinationSelected,
    List<TimelineRowDefinition>? rowDefinitions,
  }) {
    final effectiveGroupWithMembers = groupWithMembers ?? testGroupWithMembers;
    final effectiveRowDefinitions =
        rowDefinitions ??
        buildTimelineRows(
          groupWithMembers: effectiveGroupWithMembers,
          onDestinationSelected: onDestinationSelected,
        );

    return ProviderScope(
      overrides: [
        tripEntryQueryServiceProvider.overrideWithValue(
          tripEntryQueryService ?? mockTripEntryQueryService,
        ),
        dvcPointUsageQueryServiceProvider.overrideWithValue(
          dvcPointUsageService ?? dvcPointUsageQueryService,
        ),
        groupEventQueryServiceProvider.overrideWithValue(
          groupEventService ?? groupEventQueryService,
        ),
        groupEventRepositoryProvider.overrideWithValue(
          groupEventRepo ?? groupEventRepository,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200, // より広い画面サイズを設定
            height: 800,
            child: Timeline(
              groupWithMembers: effectiveGroupWithMembers,
              onBackPressed: onBackPressed,
              onSetRefreshCallback: onSetRefreshCallback,
              rowDefinitions: effectiveRowDefinitions,
            ),
          ),
        ),
      ),
    );
  }

  Widget createControllerProbeWidget({
    required GroupDto groupWithMembers,
    required void Function(TimelineController controller) onBuilt,
    TripEntryQueryService? tripEntryQueryService,
    DvcPointUsageQueryService? dvcPointUsageService,
    GroupEventQueryService? groupEventService,
    GroupEventRepository? groupEventRepo,
    void Function(RefreshTimelineCallback)? onSetRefreshCallback,
  }) {
    return ProviderScope(
      overrides: [
        tripEntryQueryServiceProvider.overrideWithValue(
          tripEntryQueryService ?? mockTripEntryQueryService,
        ),
        dvcPointUsageQueryServiceProvider.overrideWithValue(
          dvcPointUsageService ?? dvcPointUsageQueryService,
        ),
        groupEventQueryServiceProvider.overrideWithValue(
          groupEventService ?? groupEventQueryService,
        ),
        groupEventRepositoryProvider.overrideWithValue(
          groupEventRepo ?? groupEventRepository,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: _TimelineControllerProbe(
            groupWithMembers: groupWithMembers,
            onBuilt: onBuilt,
            onSetRefreshCallback: onSetRefreshCallback,
          ),
        ),
      ),
    );
  }

  void setCustomViewSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('GroupTimeline', () {
    testWidgets('GroupTimelineウィジェットが正しく表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('group_timeline')), findsOneWidget);
    });

    testWidgets('グループ名が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('テストグループ'), findsOneWidget);
    });

    testWidgets('右上に設定アイコンが表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('timeline_settings_button')), findsOneWidget);
      expect(find.byIcon(Icons.settings_input_composite), findsOneWidget);
    });

    testWidgets('DVC行に編集アイコンボタンが表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('DVC'), findsOneWidget);
      expect(
        find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
          matching: find.byIcon(Icons.edit),
        ),
        findsOneWidget,
      );
    });

    testWidgets('DVCポイント利用の編集ボタンをタップすると遷移要求が通知される', (
      WidgetTester tester,
    ) async {
      // Arrange
      GroupTimelineDestination? selectedDestination;

      await tester.pumpWidget(
        createTestWidget(
          onDestinationSelected: (destination) {
            selectedDestination = destination;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(
        find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        selectedDestination,
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );
    });

    testWidgets('DVC行の固定セル全体をタップすると遷移要求が通知される', (WidgetTester tester) async {
      // Arrange
      GroupTimelineDestination? selectedDestination;

      await tester.pumpWidget(
        createTestWidget(
          onDestinationSelected: (destination) {
            selectedDestination = destination;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(const Key('fixed_row_2')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        selectedDestination,
        GroupTimelineDvcPointCalculationDestination(
          groupId: testGroupWithMembers.id,
        ),
      );
    });

    testWidgets('DVCポイント利用行に利用年月・利用ポイント・メモが表示される', (WidgetTester tester) async {
      // Arrange
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime(currentYear, 4);
      final nextYearMonth = DateTime(currentYear + 1, 1);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          dvcPointUsageService: _FakeDvcPointUsageQueryService([
            DvcPointUsageDto(
              id: 'usage1',
              groupId: '1',
              usageYearMonth: currentMonth,
              usedPoint: 120,
              memo: 'メモ1',
            ),
            DvcPointUsageDto(
              id: 'usage2',
              groupId: '1',
              usageYearMonth: nextYearMonth,
              usedPoint: 80,
              memo: 'メモ2',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final currentYearCell = find.byKey(
        Key('dvc_point_usage_cell_$currentYear'),
      );
      final nextYearCell = find.byKey(
        Key('dvc_point_usage_cell_${currentYear + 1}'),
      );

      expect(
        find.descendant(
          of: currentYearCell,
          matching: find.text('${currentMonth.year}-04  120pt'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: currentYearCell, matching: find.text('メモ1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: nextYearCell,
          matching: find.text('${nextYearMonth.year}-01  80pt'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nextYearCell, matching: find.text('メモ2')),
        findsOneWidget,
      );
    });

    testWidgets('グループイベント行に対象年のメモが表示される', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-1',
              groupId: '1',
              year: currentYear,
              memo: '運動会',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      final currentYearCell = find.byKey(Key('group_event_cell_$currentYear'));
      expect(
        find.descendant(of: currentYearCell, matching: find.text('運動会')),
        findsOneWidget,
      );
    });

    testWidgets('グループイベントセルをタップすると編集ダイアログが開く', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-1',
              groupId: '1',
              year: currentYear,
              memo: '運動会',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('group_event_cell_$currentYear')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('group_event_edit_dialog_$currentYear')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('group_event_edit_field_$currentYear')),
        findsOneWidget,
      );
      final textField = tester.widget<TextField>(
        find.byKey(Key('group_event_edit_field_$currentYear')),
      );
      expect(textField.controller?.text, '運動会');
    });

    testWidgets('グループイベント編集ダイアログを閉じたあとも再度開ける', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-1',
              groupId: '1',
              year: currentYear,
              memo: '運動会',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      final cellFinder = find.byKey(Key('group_event_cell_$currentYear'));
      final fieldFinder = find.byKey(
        Key('group_event_edit_field_$currentYear'),
      );

      await tester.tap(cellFinder);
      await tester.pumpAndSettle();
      expect(fieldFinder, findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(fieldFinder, findsNothing);

      await tester.tap(cellFinder);
      await tester.pumpAndSettle();
      expect(fieldFinder, findsOneWidget);
      final reopenedTextField = tester.widget<TextField>(fieldFinder);
      expect(reopenedTextField.controller?.text, '運動会');
    });

    testWidgets('グループイベントのメモを保存すると更新される', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;
      final repository = _FakeGroupEventRepository();

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-1',
              groupId: '1',
              year: currentYear,
              memo: '運動会',
            ),
          ]),
          groupEventRepo: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('group_event_cell_$currentYear')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(Key('group_event_edit_field_$currentYear')),
        '太郎の運動会',
      );
      await tester.tap(find.byKey(Key('group_event_save_button_$currentYear')));
      await tester.pumpAndSettle();

      expect(repository.savedEvents, [
        GroupEvent(
          id: 'event-1',
          groupId: '1',
          year: currentYear,
          memo: '太郎の運動会',
        ),
      ]);
      expect(find.text('太郎の運動会'), findsOneWidget);
    });

    testWidgets('グループイベントのメモを空欄で保存すると削除される', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;
      final repository = _FakeGroupEventRepository();

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-1',
              groupId: '1',
              year: currentYear,
              memo: '運動会',
            ),
          ]),
          groupEventRepo: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('group_event_cell_$currentYear')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(Key('group_event_edit_field_$currentYear')),
        '',
      );
      await tester.tap(find.byKey(Key('group_event_save_button_$currentYear')));
      await tester.pumpAndSettle();

      expect(repository.deletedEventIds, ['event-1']);
      expect(find.text('運動会'), findsNothing);
    });

    testWidgets('旅行行の取得Providerはoverride差し替え時に再評価される', (
      WidgetTester tester,
    ) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        createTestWidget(
          tripEntryQueryService: _FakeTripEntryQueryService([
            TripEntryDto(
              id: 'trip-1',
              groupId: '1',
              tripYear: currentYear,
              tripName: '初回旅行',
              tripStartDate: DateTime(currentYear, 4, 1),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初回旅行'), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          tripEntryQueryService: _FakeTripEntryQueryService([
            TripEntryDto(
              id: 'trip-2',
              groupId: '1',
              tripYear: currentYear,
              tripName: '差し替え後旅行',
              tripStartDate: DateTime(currentYear, 5, 1),
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('差し替え後旅行'), findsOneWidget);
      expect(find.text('初回旅行'), findsNothing);
    });

    testWidgets('DVC行の取得Providerはoverride差し替え時に再評価される', (
      WidgetTester tester,
    ) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        createTestWidget(
          dvcPointUsageService: _FakeDvcPointUsageQueryService([
            DvcPointUsageDto(
              id: 'usage-1',
              groupId: '1',
              usageYearMonth: DateTime(currentYear, 4),
              usedPoint: 120,
              memo: '初回DVC',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初回DVC'), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          dvcPointUsageService: _FakeDvcPointUsageQueryService([
            DvcPointUsageDto(
              id: 'usage-2',
              groupId: '1',
              usageYearMonth: DateTime(currentYear, 5),
              usedPoint: 80,
              memo: '差し替え後DVC',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('差し替え後DVC'), findsOneWidget);
      expect(find.text('初回DVC'), findsNothing);
    });

    testWidgets('イベント行の取得Providerはoverride差し替え時に再評価される', (
      WidgetTester tester,
    ) async {
      final currentYear = DateTime.now().year;

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-1',
              groupId: '1',
              year: currentYear,
              memo: '初回イベント',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初回イベント'), findsOneWidget);

      await tester.pumpWidget(
        createTestWidget(
          groupEventService: _FakeGroupEventQueryService([
            GroupEventDto(
              id: 'event-2',
              groupId: '1',
              year: currentYear,
              memo: '差し替え後イベント',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('差し替え後イベント'), findsOneWidget);
      expect(find.text('初回イベント'), findsNothing);
    });

    testWidgets('DVCポイント利用でメモが空の場合は末尾改行なしで表示される', (WidgetTester tester) async {
      // Arrange
      final currentYear = DateTime.now().year;
      final currentMonth = DateTime(currentYear, 4);
      final nextYearMonth = DateTime(currentYear + 1, 1);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          dvcPointUsageService: _FakeDvcPointUsageQueryService([
            DvcPointUsageDto(
              id: 'usage1',
              groupId: '1',
              usageYearMonth: currentMonth,
              usedPoint: 120,
            ),
            DvcPointUsageDto(
              id: 'usage2',
              groupId: '1',
              usageYearMonth: nextYearMonth,
              usedPoint: 80,
              memo: '  ',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final currentYearCell = find.byKey(
        Key('dvc_point_usage_cell_$currentYear'),
      );
      final nextYearCell = find.byKey(
        Key('dvc_point_usage_cell_${currentYear + 1}'),
      );

      expect(
        find.descendant(
          of: currentYearCell,
          matching: find.text('${currentMonth.year}-04  120pt'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: nextYearCell,
          matching: find.text('${nextYearMonth.year}-01  80pt'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('DVCセルをタップすると対象年セルの全件詳細がポップアップ表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      final currentYear = DateTime.now().year;
      final yearCell = Key('dvc_point_usage_cell_$currentYear');
      const longMemo = 'このメモはポップアップで省略されずに全文表示されるべき長文です。';

      await tester.pumpWidget(
        createTestWidget(
          dvcPointUsageService: _FakeDvcPointUsageQueryService([
            DvcPointUsageDto(
              id: 'usage1',
              groupId: '1',
              usageYearMonth: DateTime(currentYear, 1),
              usedPoint: 30,
              memo: 'メモ1',
            ),
            DvcPointUsageDto(
              id: 'usage2',
              groupId: '1',
              usageYearMonth: DateTime(currentYear, 4),
              usedPoint: 60,
              memo: 'メモ2',
            ),
            DvcPointUsageDto(
              id: 'usage3',
              groupId: '1',
              usageYearMonth: DateTime(currentYear, 8),
              usedPoint: 90,
              memo: longMemo,
            ),
            DvcPointUsageDto(
              id: 'usage4',
              groupId: '1',
              usageYearMonth: DateTime(currentYear, 12),
              usedPoint: 120,
              memo: 'メモ4',
            ),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(yearCell));
      await tester.pumpAndSettle();

      // Assert
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('利用年月: $currentYear-01'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('利用ポイント: 30pt')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('メモ: メモ1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('利用年月: $currentYear-12'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('利用ポイント: 120pt')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('メモ: $longMemo')),
        findsOneWidget,
      );
    });

    testWidgets('年表のヘッダー行に年の列が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // 現在の年が和暦フォーマットで表示されることを確認
      final currentYear = DateTime.now().year;
      expect(find.textContaining('$currentYear年'), findsOneWidget);
      expect(find.textContaining('年)'), findsNWidgets(11)); // 前後5年分合計11年
    });

    testWidgets('年表の行にメンバー名が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('タロちゃん'), findsOneWidget);
    });

    testWidgets('現在の年を中央として前後5年分の年が表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final currentYear = DateTime.now().year;
      // 合計11年分（-5年から+5年）の年が表示されることを確認
      for (int i = -5; i <= 5; i++) {
        final year = currentYear + i;
        expect(find.textContaining('$year年'), findsOneWidget);
      }
    });

    testWidgets('「さらに表示する」ボタンが先頭と末尾に表示される', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('さらに表示'), findsNWidgets(2));
    });

    testWidgets('先頭の「さらに表示する」ボタンをタップすると、さらに過去5年分が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final currentYear = DateTime.now().year;

      // 初期状態では2020年が最古（現在年-5年）
      expect(find.textContaining('${currentYear - 5}年'), findsOneWidget);
      expect(find.textContaining('${currentYear - 10}年'), findsNothing);

      // Act - 先頭の「さらに表示」ボタンの機能を呼び出し
      final showMorePastButton = tester.widget<TextButton>(
        find.byKey(const Key('show_more_past')),
      );
      showMorePastButton.onPressed!();
      await tester.pumpAndSettle();

      // Assert - さらに過去5年分が表示される
      for (int i = -10; i <= -6; i++) {
        final year = currentYear + i;
        expect(find.textContaining('$year年'), findsOneWidget);
      }
    });

    testWidgets('末尾の「さらに表示する」ボタンをタップすると、さらに未来5年分が表示される', (
      WidgetTester tester,
    ) async {
      // Arrange
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final currentYear = DateTime.now().year;

      // 初期状態では2030年が最新（現在年+5年）
      expect(find.textContaining('${currentYear + 5}年'), findsOneWidget);
      expect(find.textContaining('${currentYear + 10}年'), findsNothing);

      // Act - 末尾の「さらに表示」ボタンの機能を呼び出し
      final showMoreFutureButton = tester.widget<TextButton>(
        find.byKey(const Key('show_more_future')),
      );
      showMoreFutureButton.onPressed!();
      await tester.pumpAndSettle();

      // Assert - さらに未来5年分が表示される
      for (int i = 6; i <= 10; i++) {
        final year = currentYear + i;
        expect(find.textContaining('$year年'), findsOneWidget);
      }
    });

    testWidgets('メンバー行の各年に年齢が表示される', (WidgetTester tester) async {
      // Arrange
      final birthday = DateTime(1990, 6, 1);
      testGroupWithMembers = testGroupWithMembers.copyWith(
        members: [
          testGroupWithMembers.members.first.copyWith(birthday: birthday),
        ],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final currentYear = DateTime.now().year;
      final currentAge = currentYear - birthday.year;
      final futureAge = currentYear + 5 - birthday.year;

      // Assert
      expect(find.textContaining('$currentAge歳'), findsOneWidget);
      expect(find.textContaining('$futureAge歳'), findsOneWidget);
    });

    testWidgets('生年月日未設定のメンバーには年齢を表示しない', (WidgetTester tester) async {
      // Arrange
      testGroupWithMembers = testGroupWithMembers.copyWith(
        members: [testGroupWithMembers.members.first.copyWith(birthday: null)],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('歳'), findsNothing);
    });

    testWidgets('保存された表示設定が年齢・学年・厄年の表示に反映される', (WidgetTester tester) async {
      // Arrange
      final currentYear = DateTime.now().year;
      final gradeBirthday = DateTime(currentYear - 6, 1, 1);
      final yakudoshiBirthday = DateTime(currentYear - 24, 1, 1);

      SharedPreferences.setMockInitialValues({
        TimelineDisplaySettings.showAgeKey: false,
        TimelineDisplaySettings.showGradeKey: true,
        TimelineDisplaySettings.showYakudoshiKey: false,
      });

      testGroupWithMembers = testGroupWithMembers.copyWith(
        members: [
          testGroupWithMembers.members.first.copyWith(
            birthday: gradeBirthday,
            gender: '男性',
          ),
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group1',
            displayName: 'ジロちゃん',
            email: 'jiro@example.com',
            birthday: yakudoshiBirthday,
            gender: '男性',
          ),
        ],
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final expectedAgeLabel = '${currentYear - gradeBirthday.year}歳';
      expect(find.textContaining(expectedAgeLabel), findsNothing);
      expect(find.textContaining('小学1年生'), findsOneWidget);
      expect(find.textContaining('本厄'), findsNothing);
    });

    testWidgets('設定から年齢・学年・厄年の表示を切り替えて保存できる', (WidgetTester tester) async {
      // Arrange
      final currentYear = DateTime.now().year;
      final gradeBirthday = DateTime(currentYear - 6, 1, 1);
      final yakudoshiBirthday = DateTime(currentYear - 24, 1, 1);

      testGroupWithMembers = testGroupWithMembers.copyWith(
        members: [
          testGroupWithMembers.members.first.copyWith(
            birthday: gradeBirthday,
            gender: '男性',
          ),
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group1',
            displayName: 'ジロちゃん',
            email: 'jiro@example.com',
            birthday: yakudoshiBirthday,
            gender: '男性',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final expectedAgeLabel = '${currentYear - gradeBirthday.year}歳';
      expect(find.textContaining(expectedAgeLabel), findsWidgets);
      expect(find.textContaining('小学1年生'), findsOneWidget);
      expect(find.textContaining('本厄'), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const Key('timeline_settings_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_show_age')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_show_grade')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_show_yakudoshi')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining(expectedAgeLabel), findsNothing);
      expect(find.textContaining('小学1年生'), findsNothing);
      expect(find.textContaining('本厄'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(TimelineDisplaySettings.showAgeKey), isFalse);
      expect(prefs.getBool(TimelineDisplaySettings.showGradeKey), isFalse);
      expect(prefs.getBool(TimelineDisplaySettings.showYakudoshiKey), isFalse);
    });

    testWidgets('初期表示時に現在の年が画面の中央にスクロールされる', (WidgetTester tester) async {
      // Arrange
      setCustomViewSize(tester, const Size(1001, 601));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act & Assert
      // 水平スクロールビューのScrollControllerを取得
      final scrollView = find.byType(SingleChildScrollView).first;
      final scrollController = tester
          .widget<SingleChildScrollView>(scrollView)
          .controller;

      // 初期表示時に現在の年が中央に表示されるようにスクロール位置が調整されていることを確認
      expect(scrollController, isNotNull);
      expect(scrollController!.hasClients, isTrue);

      // スクロール位置が0（左端）ではないことを確認（中央にスクロールされている）
      expect(scrollController.offset, greaterThan(0));
    });

    testWidgets('現在年スクロール位置は実際のviewport幅を基準に計算される', (
      WidgetTester tester,
    ) async {
      setCustomViewSize(tester, const Size(1001, 601));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final scrollView = find.byType(SingleChildScrollView).first;
      final scrollController = tester
          .widget<SingleChildScrollView>(scrollView)
          .controller!;

      final totalWidth = (2 * 100.0) + (11 * 120.0);
      final expectedOffset =
          ((totalWidth / 2) - (scrollController.position.viewportDimension / 2))
              .clamp(0.0, scrollController.position.maxScrollExtent);

      expect(scrollController.offset, closeTo(expectedOffset, 0.1));
    });

    testWidgets('行の高さをドラッグで変更できるリサイザーが表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      // 行の境界にリサイザーが表示されることを確認（すべての行にリサイザーがある）
      expect(
        find.byKey(const Key('row_resizer_icon_0')),
        findsOneWidget,
      ); // 旅行行のリサイザー
      expect(
        find.byKey(const Key('row_resizer_icon_1')),
        findsOneWidget,
      ); // イベント行のリサイザー
      expect(
        find.byKey(const Key('row_resizer_icon_2')),
        findsOneWidget,
      ); // DVCポイント利用行のリサイザー
      expect(
        find.byKey(const Key('row_resizer_icon_3')),
        findsOneWidget,
      ); // メンバー行のリサイザー
    });

    testWidgets('行の高さをドラッグで変更すると、固定列も連動して高さが変わる', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 初期の行の高さを取得
      final initialFixedRowHeight = tester
          .getSize(find.byKey(const Key('fixed_row_0')))
          .height;
      final initialScrollableRowHeight = tester
          .getSize(find.byKey(const Key('scrollable_row_0')))
          .height;

      expect(initialFixedRowHeight, equals(100.0)); // デフォルト値の確認
      expect(initialScrollableRowHeight, equals(100.0));

      // Act
      // 旅行行のリサイザーをドラッグ
      final resizerKey = find.byKey(const Key('row_resizer_icon_0'));
      expect(resizerKey, findsOneWidget);
      await _dragResizer(tester, resizerKey, const Offset(0, 20)); // 下に20px移動
      await tester.pumpAndSettle();

      // Assert
      // 固定列とスクロール可能列の両方の行の高さが変更されていることを確認
      final finalFixedRowHeight = tester
          .getSize(find.byKey(const Key('fixed_row_0')))
          .height;
      final finalScrollableRowHeight = tester
          .getSize(find.byKey(const Key('scrollable_row_0')))
          .height;

      expect(finalFixedRowHeight, equals(initialFixedRowHeight + 20));
      expect(finalScrollableRowHeight, equals(initialScrollableRowHeight + 20));
    });

    testWidgets('複数の行の高さを個別に変更できる', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 初期の行の高さを取得
      final initialTravelRowHeight = tester
          .getSize(find.byKey(const Key('fixed_row_0')))
          .height;
      final initialEventRowHeight = tester
          .getSize(find.byKey(const Key('fixed_row_1')))
          .height;

      // Act
      // 旅行行のリサイザーをドラッグ
      final travelResizer = find.byKey(const Key('row_resizer_icon_0'));
      expect(travelResizer, findsOneWidget);
      await _dragResizer(tester, travelResizer, const Offset(0, 10));
      await tester.pumpAndSettle();

      // イベント行のリサイザーをドラッグ
      final eventResizer = find.byKey(const Key('row_resizer_icon_1'));
      expect(eventResizer, findsOneWidget);
      await _dragResizer(tester, eventResizer, const Offset(0, 30));
      await tester.pumpAndSettle();

      // Assert
      // 各行の高さが個別に変更されていることを確認
      final finalTravelRowHeight = tester
          .getSize(find.byKey(const Key('fixed_row_0')))
          .height;
      final finalEventRowHeight = tester
          .getSize(find.byKey(const Key('fixed_row_1')))
          .height;

      expect(finalTravelRowHeight, equals(initialTravelRowHeight + 10));
      expect(finalEventRowHeight, equals(initialEventRowHeight + 30));
    });

    testWidgets('onBackPressedが設定されている場合、左上に戻るアイコンが表示される', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget(onBackPressed: () {}));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('back_button')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('onBackPressedが設定されていない場合、戻るアイコンは表示されない', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('back_button')), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('戻るアイコンをタップするとコールバック関数が呼ばれる', (WidgetTester tester) async {
      // Arrange
      bool callbackCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          onBackPressed: () {
            callbackCalled = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(callbackCalled, isTrue);
    });

    testWidgets('旅行セルをタップすると遷移要求が通知される', (WidgetTester tester) async {
      // Arrange
      GroupTimelineDestination? selectedDestination;

      await tester.pumpWidget(
        createTestWidget(
          onDestinationSelected: (destination) {
            selectedDestination = destination;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Act - 旅行行（最初の行）の年列セルを特定してタップ
      // 旅行行のスクロール可能な行を特定
      final scrollableRow = find.byKey(const Key('scrollable_row_0'));
      expect(scrollableRow, findsOneWidget);

      // スクロール可能な行の中の年列セルをタップ
      await tester.tap(scrollableRow);
      await tester.pumpAndSettle();

      // Assert - 旅行管理画面への遷移要求が通知される
      expect(
        selectedDestination,
        isA<GroupTimelineTripManagementDestination>()
            .having(
              (destination) => destination.groupId,
              'groupId',
              testGroupWithMembers.id,
            )
            .having((destination) => destination.year, 'year', isA<int>()),
      );
    });

    testWidgets('旅行行に対象年の旅行一覧が表示される', (WidgetTester tester) async {
      // Arrange
      final currentYear = DateTime.now().year;
      final testTrips = [
        TripEntryDto(
          id: '1',
          groupId: '1',
          tripYear: currentYear,
          tripName: '北海道旅行',
          tripStartDate: DateTime(currentYear, 8, 15),
          tripEndDate: DateTime(currentYear, 8, 18),
        ),
        TripEntryDto(
          id: '2',
          groupId: '1',
          tripYear: currentYear,
          tripName: null,
          tripStartDate: DateTime(currentYear, 12, 25),
          tripEndDate: DateTime(currentYear, 12, 27),
        ),
      ];

      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          '1',
          currentYear,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => testTrips);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('北海道旅行'), findsAtLeastNWidgets(1));
      expect(find.textContaining('$currentYear/08'), findsAtLeastNWidgets(1));
      expect(find.textContaining('$currentYear/12'), findsAtLeastNWidgets(1));
    });

    testWidgets('onSetRefreshCallbackが設定された場合、リフレッシュコールバックが呼ばれる', (
      WidgetTester tester,
    ) async {
      // Arrange
      RefreshTimelineCallback? capturedCallback;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          onSetRefreshCallback: (callback) {
            capturedCallback = callback;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Assert - コールバックが設定されることを確認
      expect(capturedCallback, isNotNull);
    });

    testWidgets('リフレッシュコールバックは行更新キーだけを進める', (WidgetTester tester) async {
      RefreshTimelineCallback? capturedCallback;
      final capturedControllers = <TimelineController>[];

      await tester.pumpWidget(
        createControllerProbeWidget(
          groupWithMembers: testGroupWithMembers,
          onBuilt: capturedControllers.add,
          onSetRefreshCallback: (callback) {
            capturedCallback = callback;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedCallback, isNotNull);
      expect(capturedControllers.last.refreshKey, 0);

      await capturedCallback!();
      await tester.pumpAndSettle();

      expect(capturedControllers.last.refreshKey, 1);
    });

    testWidgets('年範囲変更時にonSetRefreshCallbackを再登録しない', (
      WidgetTester tester,
    ) async {
      var callbackSetCount = 0;

      await tester.pumpWidget(
        createTestWidget(
          onSetRefreshCallback: (_) {
            callbackSetCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(callbackSetCount, 1);

      final showMoreFutureButton = tester.widget<TextButton>(
        find.byKey(const Key('show_more_future')),
      );
      showMoreFutureButton.onPressed!.call();
      await tester.pumpAndSettle();

      expect(callbackSetCount, 1);
    });

    testWidgets('リフレッシュコールバック後に旅行行が再取得される', (WidgetTester tester) async {
      final currentYear = DateTime.now().year;
      var refreshCount = 0;
      RefreshTimelineCallback? capturedRefreshCallback;

      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          '1',
          any,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((invocation) {
        final year = invocation.positionalArguments[1] as int;
        if (year != currentYear) {
          return Future.value(<TripEntryDto>[]);
        }

        refreshCount++;
        return Future.value([
          TripEntryDto(
            id: 'trip_$refreshCount',
            groupId: '1',
            tripYear: currentYear,
            tripName: refreshCount == 1 ? '初回旅行' : '再取得旅行',
            tripStartDate: DateTime(currentYear, 1, 1),
          ),
        ]);
      });

      await tester.pumpWidget(
        createTestWidget(
          onSetRefreshCallback: (callback) {
            capturedRefreshCallback = callback;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('初回旅行'), findsOneWidget);
      expect(capturedRefreshCallback, isNotNull);

      await capturedRefreshCallback!();
      await tester.pumpAndSettle();

      expect(find.text('再取得旅行'), findsOneWidget);
      expect(find.text('初回旅行'), findsNothing);
    });

    testWidgets('グループ切り替え時は旧グループの旅行取得結果を引き継がず新グループを再取得する', (
      WidgetTester tester,
    ) async {
      final firstGroupCompleter = Completer<List<TripEntryDto>>();
      final requestedGroupIds = <String>[];
      int? firstRequestedYear;
      var hasReturnedSecondGroupTrip = false;
      final secondGroup = testGroupWithMembers.copyWith(
        id: '2',
        name: '切り替え後グループ',
      );

      when(
        mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
          any,
          any,
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((invocation) {
        final groupId = invocation.positionalArguments[0] as String;
        final year = invocation.positionalArguments[1] as int;
        requestedGroupIds.add(groupId);
        firstRequestedYear ??= year;

        if (groupId == '1') {
          return firstGroupCompleter.future;
        }

        if (!hasReturnedSecondGroupTrip) {
          hasReturnedSecondGroupTrip = true;
          return Future.value([
            TripEntryDto(
              id: 'trip_2',
              groupId: groupId,
              tripYear: year,
              tripName: '新グループ旅行',
              tripStartDate: DateTime(year, 1, 1),
            ),
          ]);
        }

        return Future.value(<TripEntryDto>[]);
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(requestedGroupIds, isNotEmpty);
      expect(requestedGroupIds.toSet(), {'1'});

      await tester.pumpWidget(createTestWidget(groupWithMembers: secondGroup));
      await tester.pump();

      expect(requestedGroupIds, contains('2'));

      firstGroupCompleter.complete([
        TripEntryDto(
          id: 'trip_1',
          groupId: '1',
          tripYear: firstRequestedYear!,
          tripName: '旧グループ旅行',
          tripStartDate: DateTime(firstRequestedYear!, 1, 1),
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('新グループ旅行'), findsOneWidget);
      expect(find.text('旧グループ旅行'), findsNothing);
    });

    testWidgets('メンバー数増加直後の最初のbuildでも行高さは不足しない', (WidgetTester tester) async {
      final capturedControllers = <TimelineController>[];
      final expandedGroup = testGroupWithMembers.copyWith(
        members: [
          ...testGroupWithMembers.members,
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group1',
            displayName: 'ハナちゃん',
            email: 'hana@example.com',
          ),
        ],
      );

      await tester.pumpWidget(
        createControllerProbeWidget(
          groupWithMembers: testGroupWithMembers,
          onBuilt: capturedControllers.add,
        ),
      );
      await tester.pumpAndSettle();

      capturedControllers.clear();

      await tester.pumpWidget(
        createControllerProbeWidget(
          groupWithMembers: expandedGroup,
          onBuilt: capturedControllers.add,
        ),
      );

      expect(capturedControllers, isNotEmpty);
      expect(
        capturedControllers.first.rowHeights.length,
        3 + expandedGroup.members.length,
      );
    });

    testWidgets('メンバー数増加直後の新しい行も最初のbuildからリサイズできる', (
      WidgetTester tester,
    ) async {
      final capturedControllers = <TimelineController>[];
      final expandedGroup = testGroupWithMembers.copyWith(
        members: [
          ...testGroupWithMembers.members,
          GroupMemberDto(
            memberId: 'member2',
            groupId: 'group1',
            displayName: 'ハナちゃん',
            email: 'hana@example.com',
          ),
        ],
      );

      await tester.pumpWidget(
        createControllerProbeWidget(
          groupWithMembers: testGroupWithMembers,
          onBuilt: capturedControllers.add,
        ),
      );
      await tester.pumpAndSettle();

      capturedControllers.clear();

      await tester.pumpWidget(
        createControllerProbeWidget(
          groupWithMembers: expandedGroup,
          onBuilt: capturedControllers.add,
        ),
      );

      expect(capturedControllers, isNotEmpty);

      final controller = capturedControllers.first;
      const pointer = 1;
      final newRowIndex = 3 + expandedGroup.members.length - 1;
      controller.onRowResizePointerDown(
        newRowIndex,
        const PointerDownEvent(pointer: pointer),
      );
      controller.onRowResizePointerMove(
        newRowIndex,
        const PointerMoveEvent(pointer: pointer, delta: Offset(0, 20)),
      );
      await tester.pump();

      expect(capturedControllers.last.rowHeights[newRowIndex], 120);
    });

    testWidgets('注入した行定義の順番で固定列が表示される', (WidgetTester tester) async {
      final firstRow = _StaticTimelineRowDefinition(label: '先頭行');
      final secondRow = _StaticTimelineRowDefinition(label: '後続行');

      await tester.pumpWidget(
        createTestWidget(rowDefinitions: [firstRow, secondRow]),
      );
      await tester.pumpAndSettle();

      expect(find.text('旅行'), findsNothing);
      expect(find.text('イベント'), findsNothing);
      expect(find.text('DVC'), findsNothing);
      expect(
        tester.getTopLeft(find.text('先頭行')).dy,
        lessThan(tester.getTopLeft(find.text('後続行')).dy),
      );
    });
  });
}

class _TimelineControllerProbe extends StatelessWidget {
  const _TimelineControllerProbe({
    required this.groupWithMembers,
    required this.onBuilt,
    this.onSetRefreshCallback,
  });

  final GroupDto groupWithMembers;
  final void Function(TimelineController controller) onBuilt;
  final void Function(RefreshTimelineCallback)? onSetRefreshCallback;

  @override
  Widget build(BuildContext context) {
    final totalDataRows = 3 + groupWithMembers.members.length;

    return HookBuilder(
      builder: (context) {
        final controller = useTimelineController(
          context: context,
          totalDataRows: totalDataRows,
          initialRowHeights: List.filled(
            totalDataRows,
            TimelineLayoutConfig.defaults.dataRowHeight,
          ),
          layoutConfig: TimelineLayoutConfig.defaults,
          onSetRefreshCallback: onSetRefreshCallback,
        );
        onBuilt(controller);
        return const SizedBox.shrink();
      },
    );
  }
}

class _FakeDvcPointUsageQueryService implements DvcPointUsageQueryService {
  const _FakeDvcPointUsageQueryService(this.pointUsages);

  final List<DvcPointUsageDto> pointUsages;

  @override
  Future<List<DvcPointUsageDto>> getDvcPointUsagesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return pointUsages.where((usage) => usage.groupId == groupId).toList();
  }
}

class _FakeTripEntryQueryService implements TripEntryQueryService {
  const _FakeTripEntryQueryService(this.tripEntries);

  final List<TripEntryDto> tripEntries;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? tasksOrderBy,
  }) async {
    for (final entry in tripEntries) {
      if (entry.id == tripId) {
        return entry;
      }
    }
    return null;
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    return tripEntries
        .where((entry) => entry.groupId == groupId && entry.tripYear == year)
        .toList();
  }
}

class _FakeGroupEventQueryService implements GroupEventQueryService {
  const _FakeGroupEventQueryService(this.groupEvents);

  final List<GroupEventDto> groupEvents;

  @override
  Future<List<GroupEventDto>> getGroupEventsByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    return groupEvents.where((event) => event.groupId == groupId).toList();
  }
}

class _StaticTimelineRowDefinition extends TimelineRowDefinition {
  const _StaticTimelineRowDefinition({required this.label});

  final String label;

  @override
  String get fixedColumnLabel => label;

  @override
  double get initialHeight => TimelineLayoutConfig.defaults.dataRowHeight;

  @override
  Color? get backgroundColor => null;

  @override
  Widget buildYearCell(
    BuildContext context,
    TimelineRowContext rowContext,
    int year,
  ) {
    return const SizedBox.shrink();
  }
}

class _FakeGroupEventRepository implements GroupEventRepository {
  final List<GroupEvent> savedEvents = [];
  final List<String> deletedEventIds = [];

  @override
  Future<void> deleteGroupEvent(String groupEventId) async {
    deletedEventIds.add(groupEventId);
  }

  @override
  Future<void> deleteGroupEventsByGroupId(String groupId) async {}

  @override
  Future<String> saveGroupEvent(GroupEvent groupEvent) async {
    savedEvents.add(groupEvent);
    if (groupEvent.id.isNotEmpty) {
      return groupEvent.id;
    }
    return 'saved-${groupEvent.groupId}-${groupEvent.year}';
  }
}

Offset _resizerDragStart(WidgetTester tester, Finder resizerFinder) {
  final topLeft = tester.getTopLeft(resizerFinder);
  return topLeft + const Offset(8, 8);
}

Future<void> _dragResizer(
  WidgetTester tester,
  Finder resizerFinder,
  Offset dragOffset,
) async {
  final gesture = await tester.startGesture(
    _resizerDragStart(tester, resizerFinder),
  );
  await tester.pump();
  await gesture.moveBy(dragOffset);
  await tester.pump();
  await gesture.up();
}
