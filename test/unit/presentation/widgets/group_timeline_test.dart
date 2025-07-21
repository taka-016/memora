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
  });
}
