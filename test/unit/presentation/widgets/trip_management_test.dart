import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/widgets/trip_management.dart';

void main() {
  group('TripManagement', () {
    const testGroupId = 'test-group-id';
    const testYear = 2025;

    testWidgets('ウィジェットが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TripManagement(groupId: testGroupId, year: testYear),
        ),
      );

      // タイトルが正しく表示されることを確認
      expect(find.text('$testYear年の旅行一覧'), findsOneWidget);

      // 戻るボタンが表示されることを確認
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // FloatingActionButtonが表示されることを確認
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // 空状態メッセージが表示されることを確認
      expect(find.text('この年の旅行はまだありません'), findsOneWidget);
    });

    testWidgets('ローディング完了後に空状態メッセージが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TripManagement(groupId: testGroupId, year: testYear),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // 空状態メッセージが表示されることを確認
      expect(find.text('この年の旅行はまだありません'), findsOneWidget);

      // FloatingActionButtonが表示されることを確認
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FloatingActionButtonをタップすると追加機能のメッセージが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const TripManagement(groupId: testGroupId, year: testYear),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // FloatingActionButtonをタップ
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // スナックバーメッセージが表示されることを確認
      expect(find.text('旅行追加機能は後で実装します'), findsOneWidget);
    });

    testWidgets('戻るボタンをタップするとNavigator.popが呼ばれる', (WidgetTester tester) async {
      bool popCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (page) {
              popCalled = true;
            },
            pages: [
              MaterialPage(
                child: const TripManagement(
                  groupId: testGroupId,
                  year: testYear,
                ),
              ),
            ],
          ),
        ),
      );

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // popが呼ばれたことを確認
      expect(popCalled, isTrue);
    });

    testWidgets('年とグループIDが正しく設定される', (WidgetTester tester) async {
      const testYear = 2024;
      const testGroupId = 'group-123';

      await tester.pumpWidget(
        MaterialApp(
          home: const TripManagement(groupId: testGroupId, year: testYear),
        ),
      );

      // タイトルに年が正しく表示されることを確認
      expect(find.text('$testYear年の旅行一覧'), findsOneWidget);
    });
  });
}
