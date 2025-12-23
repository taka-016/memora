import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:memora/presentation/features/timeline/group_timeline.dart';

import 'group_timeline_test.mocks.dart';

@GenerateMocks([TripEntryQueryService])
void main() {
  late GroupDto testGroupWithMembers;
  late MockTripEntryQueryService mockTripEntryQueryService;

  setUp(() {
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

    // デフォルトの挙動を設定
    when(
      mockTripEntryQueryService.getTripEntriesByGroupIdAndYear(
        any,
        any,
        orderBy: anyNamed('orderBy'),
      ),
    ).thenAnswer((_) async => []);
  });

  Widget createTestWidget({TripEntryQueryService? tripEntryQueryService}) {
    return ProviderScope(
      overrides: [
        tripEntryQueryServiceProvider.overrideWithValue(
          tripEntryQueryService ?? mockTripEntryQueryService,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200, // より広い画面サイズを設定
            height: 800,
            child: GroupTimeline(groupWithMembers: testGroupWithMembers),
          ),
        ),
      ),
    );
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

    testWidgets('初期表示時に現在の年が画面の中央にスクロールされる', (WidgetTester tester) async {
      // Arrange
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
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
      await tester.drag(resizerKey, const Offset(0, 20)); // 下に20px移動
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
      await tester.drag(travelResizer, const Offset(0, 10));
      await tester.pumpAndSettle();

      // イベント行のリサイザーをドラッグ
      final eventResizer = find.byKey(const Key('row_resizer_icon_1'));
      expect(eventResizer, findsOneWidget);
      await tester.drag(eventResizer, const Offset(0, 30));
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
      // Arrange
      final widget = ProviderScope(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(
            mockTripEntryQueryService,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: GroupTimeline(
                groupWithMembers: testGroupWithMembers,
                onBackPressed: () {},
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
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

      final widget = ProviderScope(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(
            mockTripEntryQueryService,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: GroupTimeline(
                groupWithMembers: testGroupWithMembers,
                onBackPressed: () {
                  callbackCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(callbackCalled, isTrue);
    });

    testWidgets('旅行セルをタップするとonTripManagementSelectedが呼ばれる', (
      WidgetTester tester,
    ) async {
      // Arrange
      String? selectedGroupId;
      int? selectedYear;

      final widget = ProviderScope(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(
            mockTripEntryQueryService,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: GroupTimeline(
                groupWithMembers: testGroupWithMembers,
                onTripManagementSelected: (groupId, year) {
                  selectedGroupId = groupId;
                  selectedYear = year;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Act - 旅行行（最初の行）の年列セルを特定してタップ
      // 旅行行のスクロール可能な行を特定
      final scrollableRow = find.byKey(const Key('scrollable_row_0'));
      expect(scrollableRow, findsOneWidget);

      // スクロール可能な行の中の年列セルをタップ
      await tester.tap(scrollableRow);
      await tester.pumpAndSettle();

      // Assert - onTripManagementSelectedが呼ばれる
      expect(selectedGroupId, equals(testGroupWithMembers.id));
      expect(selectedYear, isNotNull);
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
      VoidCallback? capturedCallback;

      Widget widget = ProviderScope(
        overrides: [
          tripEntryQueryServiceProvider.overrideWithValue(
            mockTripEntryQueryService,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GroupTimeline(
              groupWithMembers: testGroupWithMembers,
              onSetRefreshCallback: (callback) {
                capturedCallback = callback;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - コールバックが設定されることを確認
      expect(capturedCallback, isNotNull);
    });
  });
}
