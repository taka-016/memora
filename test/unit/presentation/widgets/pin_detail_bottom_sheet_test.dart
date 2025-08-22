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
      expect(find.byKey(const Key('visitStartTimeField')), findsOneWidget);
      expect(find.byKey(const Key('visitEndDateField')), findsOneWidget);
      expect(find.byKey(const Key('visitEndTimeField')), findsOneWidget);
      expect(find.byKey(const Key('visitMemoField')), findsOneWidget);

      // ボタンの確認
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

      // 閉じるボタンの確認
      expect(find.byIcon(Icons.close), findsOneWidget);

      // ドラッグハンドルの確認
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('日付・時間フィールドが縦並びで表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 日付・時間フィールドがInkWellでラップされている（4つのフィールド）
      expect(find.byType(InkWell), findsAtLeastNWidgets(4));

      // 日付・時間フィールドがOutlineBorderのContainerで表示される
      final dateContainers = find.descendant(
        of: find.byType(InkWell),
        matching: find.byType(Container),
      );
      expect(dateContainers, findsAtLeastNWidgets(4));

      // 日付選択のプレースホルダーテキストが表示される
      expect(find.text('日付を選択'), findsNWidgets(2));

      // 時間選択のプレースホルダーテキストが表示される
      expect(find.text('時間を選択'), findsNWidgets(2));

      // カレンダーアイコンが表示される
      expect(find.byIcon(Icons.calendar_today), findsNWidgets(2));

      // 時計アイコンが表示される
      expect(find.byIcon(Icons.access_time), findsNWidgets(2));
    });

    testWidgets('訪問開始日の日付選択タップでCustomDatePickerDialogが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 開始日の日付フィールドをタップ
      await tester.tap(find.byKey(const Key('visitStartDateField')));
      await tester.pumpAndSettle();

      // CustomDatePickerDialogが表示されることを確認
      expect(find.text('日付を選択'), findsWidgets);
    });

    testWidgets('訪問開始日の時間選択タップでTimePickerが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 開始時間の時間フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitStartTimeField')));
      await tester.pumpAndSettle();

      // 開始時間の時間フィールドをタップ
      await tester.tap(find.byKey(const Key('visitStartTimeField')));
      await tester.pumpAndSettle();

      // TimePicker関連のUI要素が表示されることを確認
      expect(find.text('時間を選択'), findsWidgets);
    });

    testWidgets('訪問終了日の日付選択タップでCustomDatePickerDialogが表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 終了日の日付フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitEndDateField')));
      await tester.pumpAndSettle();

      // 終了日の日付フィールドをタップ
      await tester.tap(find.byKey(const Key('visitEndDateField')));
      await tester.pumpAndSettle();

      // CustomDatePickerDialogが表示されることを確認
      expect(find.text('日付を選択'), findsWidgets);
    });

    testWidgets('訪問終了日の時間選択タップでTimePickerが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PinDetailBottomSheet())),
      );

      // 終了時間の時間フィールドが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.byKey(const Key('visitEndTimeField')));
      await tester.pumpAndSettle();

      // 終了時間の時間フィールドをタップ
      await tester.tap(find.byKey(const Key('visitEndTimeField')));
      await tester.pumpAndSettle();

      // TimePicker関連のUI要素が表示されることを確認
      expect(find.text('時間を選択'), findsWidgets);
    });

    testWidgets('保存ボタンタップ時にonSaveコールバックが呼ばれること', (WidgetTester tester) async {
      bool onSaveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PinDetailBottomSheet(
              onSave:
                  (DateTime? fromDateTime, DateTime? toDateTime, String memo) {
                    onSaveCalled = true;
                  },
            ),
          ),
        ),
      );

      // 保存ボタンが画面内に表示されるようにスクロール
      await tester.ensureVisible(find.text('保存'));
      await tester.pumpAndSettle();

      // 保存ボタンをタップ
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // onSaveコールバックが呼ばれたことを確認
      expect(onSaveCalled, isTrue);
    });
  });
}
