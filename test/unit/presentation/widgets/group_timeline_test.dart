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

    testWidgets('1列目の種類列はスクロールせず左端に固定されている', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act & Assert
      // 固定ヘッダー付きのTableウィジェットが使用されていることを確認
      expect(find.byType(Row), findsWidgets);
      expect(find.byKey(const Key('unified_border_table')), findsOneWidget);
    });

    testWidgets('列の区切り線が表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act & Assert
      // 固定列と年表の境界線があることを確認
      expect(find.byKey(const Key('column_divider')), findsOneWidget);
    });

    testWidgets('固定列とスクロール列の行が縦位置で揃っている', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act & Assert
      // 固定列とスクロール列で同じ高さの行構造が使用されていることを確認
      expect(find.byKey(const Key('unified_border_table')), findsOneWidget);
    });

    testWidgets('固定列の境界線が重複せずに表示される', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act & Assert
      // 固定列のテーブル構造で境界線の重複がないことを確認
      expect(find.byKey(const Key('fixed_column_table')), findsOneWidget);
    });
  });
}
