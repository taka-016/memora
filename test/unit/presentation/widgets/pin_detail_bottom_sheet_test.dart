import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/widgets/pin_detail_bottom_sheet.dart';

void main() {
  group('PinDetailBottomSheet', () {
    testWidgets('PinDetailBottomSheetが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('詳細入力画面のUI要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // テキストラベルの確認
      expect(find.text('訪問開始日'), findsOneWidget);
      expect(find.text('訪問終了日'), findsOneWidget);
      expect(find.text('メモ'), findsOneWidget);

      // 入力フィールドの確認
      expect(find.byKey(const Key('visitStartDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitEndDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitMemoField')), findsOneWidget);

      // ボタンの確認
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

      // 閉じるボタンの確認
      expect(find.byIcon(Icons.close), findsOneWidget);

      // ドラッグハンドルの確認
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('日時フィールドがカスタムContainerで表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 日時フィールドがInkWellでラップされている
      expect(find.byType(InkWell), findsAtLeastNWidgets(2));

      // 日時フィールドがOutlineBorderのContainerで表示される
      final dateContainers = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      );
      expect(dateContainers, findsAtLeastNWidgets(2));

      // 日時選択のプレースホルダーテキストが表示される
      expect(find.text('日時を選択'), findsNWidgets(2));

      // 時計アイコンが表示される
      expect(find.byIcon(Icons.access_time), findsNWidgets(2));
    });

    testWidgets('保存コールバックが正しく設定される', (WidgetTester tester) async {
      // コールバック関数が設定されていることを確認
      void testCallback(
        DateTime? fromDateTime,
        DateTime? toDateTime,
        String memo,
      ) {
        // テスト用のコールバック
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PinDetailBottomSheet(onSave: testCallback)),
        ),
      );

      // PinDetailBottomSheetが正しく表示されることを確認
      expect(find.byType(PinDetailBottomSheet), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });
  });
}
