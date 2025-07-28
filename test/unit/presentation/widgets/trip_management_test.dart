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
          home: Scaffold(
            body: const TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
            ),
          ),
        ),
      );

      // タイトルが正しく表示されることを確認
      expect(find.text('$testYear年の旅行管理'), findsOneWidget);

      // 戻るボタンは表示されない（onBackPressedがnullのため）
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // 旅行追加ボタンが表示されることを確認
      expect(find.text('旅行追加'), findsOneWidget);

      // 空状態メッセージが表示されることを確認
      expect(find.text('この年の旅行はまだありません'), findsOneWidget);
    });

    testWidgets('ローディング完了後に空状態メッセージが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
            ),
          ),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // 空状態メッセージが表示されることを確認
      expect(find.text('この年の旅行はまだありません'), findsOneWidget);

      // 旅行追加ボタンが表示されることを確認
      expect(find.text('旅行追加'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('旅行追加ボタンをタップするとTripEditModalが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
            ),
          ),
        ),
      );

      // ローディング完了まで待機
      await tester.pumpAndSettle();

      // 旅行追加ボタンをタップ
      await tester.tap(find.text('旅行追加'));
      await tester.pumpAndSettle();

      // TripEditModalが表示されることを確認
      expect(find.text('旅行新規作成'), findsOneWidget);
    });

    testWidgets('戻るボタンをタップするとonBackPressedが呼ばれる', (WidgetTester tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: () {
                backPressed = true;
              },
            ),
          ),
        ),
      );

      // 戻るボタンをタップ
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // onBackPressedが呼ばれたことを確認
      expect(backPressed, isTrue);
    });

    testWidgets('年とグループIDが正しく設定される', (WidgetTester tester) async {
      const testYear = 2024;
      const testGroupId = 'group-123';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const TripManagement(
              groupId: testGroupId,
              year: testYear,
              onBackPressed: null,
            ),
          ),
        ),
      );

      // タイトルに年が正しく表示されることを確認
      expect(find.text('$testYear年の旅行管理'), findsOneWidget);
    });
  });
}
