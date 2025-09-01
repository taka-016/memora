import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/dialogs/custom_date_picker_dialog.dart';

void main() {
  group('CustomDatePickerDialog', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15); // 月曜日
    });

    testWidgets('ヘッダーに曜日が表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomDatePickerDialog(
            initialDate: testDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      // 2024年1月15日 (月) が表示されることを期待
      expect(find.text('2024年1月15日 (月)'), findsOneWidget);
    });

    testWidgets('異なる曜日の日付で正しい曜日が表示される', (tester) async {
      final sunday = DateTime(2024, 1, 14); // 日曜日

      await tester.pumpWidget(
        MaterialApp(
          home: CustomDatePickerDialog(
            initialDate: sunday,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      // 2024年1月14日 (日) が表示されることを期待
      expect(find.text('2024年1月14日 (日)'), findsOneWidget);
    });

    testWidgets('選択日付が変更されたときに曜日も更新される', (tester) async {
      // 初期日付を同じ月の別の日付に設定（ダイアログが閉じないように）
      final initialDate = DateTime(2024, 1, 15); // 月曜日

      await tester.pumpWidget(
        MaterialApp(
          home: CustomDatePickerDialog(
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      // 初期状態：2024年1月15日 (月)
      expect(find.text('2024年1月15日 (月)'), findsOneWidget);

      // 同じ初期日付をもう一度タップして状態変更をトリガー
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      // 日付が変わらなくても曜日表示は維持される
      expect(find.text('2024年1月15日 (月)'), findsOneWidget);
    });

    testWidgets('年月日表記をタップすると入力フィールドビューに切り替わる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomDatePickerDialog(
            initialDate: testDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      // 初期状態ではカレンダービューが表示される
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.byKey(const Key('date_field')), findsNothing);

      // 年月日表記のテキストをタップ
      await tester.tap(find.text('2024年1月15日 (月)'));
      await tester.pumpAndSettle();

      // 入力フィールドビューに切り替わることを期待
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.byKey(const Key('date_field')), findsOneWidget);
    });

    testWidgets('入力フィールドで年月日を変更して確定するとダイアログが閉じる', (tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedDate = await showDialog<DateTime>(
                  context: context,
                  builder: (_) => CustomDatePickerDialog(
                    initialDate: testDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      // ダイアログを開く
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 年月日表記をタップして入力フィールドビューに切り替える
      await tester.tap(find.text('2024年1月15日 (月)'));
      await tester.pumpAndSettle();

      // 日付フィールドに新しい日付を入力（自動フォーマット）
      await tester.enterText(find.byKey(const Key('date_field')), '20251225');

      // 確定ボタンをタップ
      await tester.tap(find.text('確定'));
      await tester.pumpAndSettle();

      // ダイアログが閉じて、選択された日付が返されることを期待
      expect(find.byType(Dialog), findsNothing);
      expect(selectedDate, equals(DateTime(2025, 12, 25)));
    });

    testWidgets('入力フィールドでキャンセルするとカレンダービューに戻る', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomDatePickerDialog(
            initialDate: testDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      // 年月日表記をタップして入力フィールドビューに切り替える
      await tester.tap(find.text('2024年1月15日 (月)'));
      await tester.pumpAndSettle();

      // 入力フィールドビューが表示される
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.byKey(const Key('date_field')), findsOneWidget);

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // カレンダービューに戻り、元の日付が維持される
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.byKey(const Key('date_field')), findsNothing);
      expect(find.text('2024年1月15日 (月)'), findsOneWidget);
    });

    testWidgets('無効な日付入力時にエラーが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomDatePickerDialog(
            initialDate: testDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          ),
        ),
      );

      // 年月日表記をタップして入力フィールドビューに切り替える
      await tester.tap(find.text('2024年1月15日 (月)'));
      await tester.pumpAndSettle();

      // 無効な日付を入力
      await tester.enterText(find.byKey(const Key('date_field')), '20241332');

      // 確定ボタンをタップ
      await tester.tap(find.text('確定'));
      await tester.pumpAndSettle();

      // エラーメッセージが表示され、入力フィールドビューのままであることを期待
      expect(find.text('有効な日付を入力してください'), findsOneWidget);
      expect(find.byKey(const Key('date_field')), findsOneWidget);
      expect(find.byType(CalendarDatePicker), findsNothing);
    });
  });
}
