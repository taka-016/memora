import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/get_groups_with_members_usecase.dart';
import 'package:memora/domain/entities/group.dart';
import 'package:memora/domain/entities/member.dart';
import 'package:memora/presentation/widgets/group_timeline.dart';

void main() {
  late Member testMember;
  late GroupWithMembers testGroupWithMembers;

  setUp(() {
    testMember = Member(
      id: 'member1',
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

    testGroupWithMembers = GroupWithMembers(
      group: Group(id: '1', administratorId: 'admin1', name: 'テストグループ'),
      members: [testMember],
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200, // より広い画面サイズを設定
          height: 800,
          child: GroupTimeline(groupWithMembers: testGroupWithMembers),
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
      await tester.drag(
        resizerKey,
        const Offset(0, 20),
        warnIfMissed: false,
      ); // 下に20px移動
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
      await tester.drag(
        find.byKey(const Key('row_resizer_icon_0')),
        const Offset(0, 10),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // イベント行のリサイザーをドラッグ
      await tester.drag(
        find.byKey(const Key('row_resizer_icon_1')),
        const Offset(0, 30),
        warnIfMissed: false,
      );
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
      final widget = MaterialApp(
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

      final widget = MaterialApp(
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
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(callbackCalled, isTrue);
    });
  });
}
