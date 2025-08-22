import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/widgets/custom_datetime_picker_dialog.dart';

void main() {
  group('CustomDateTimePickerDialog', () {
    final initialDateTime = DateTime(2024, 1, 1, 10, 30);
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    testWidgets('CustomDateTimePickerDialogが正しく表示される', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDateTimePickerDialog(
              initialDateTime: initialDateTime,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        ),
      );

      expect(find.byType(CustomDateTimePickerDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('日時ヘッダーが正しく表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDateTimePickerDialog(
              initialDateTime: initialDateTime,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        ),
      );

      // 日時ヘッダーが表示される
      expect(find.text('2024年1月1日 (月) 10:30'), findsOneWidget);
    });

    testWidgets('カレンダーと時刻選択ボタンが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDateTimePickerDialog(
              initialDateTime: initialDateTime,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        ),
      );

      // カレンダーピッカーが表示される
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // 時刻選択ボタンが表示される
      expect(find.text('時刻を選択 (10:30)'), findsOneWidget);

      // 確定ボタンが表示される
      expect(find.text('確定'), findsOneWidget);
    });

    testWidgets('入力モードに切り替わる', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomDateTimePickerDialog(
              initialDateTime: initialDateTime,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        ),
      );

      // ヘッダーをタップして入力モードに切り替える
      await tester.tap(find.text('2024年1月1日 (月) 10:30'));
      await tester.pumpAndSettle();

      // 入力フィールドが表示される
      expect(find.byKey(const Key('datetime_field')), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('確定'), findsOneWidget);
    });
  });

  group('showCustomDateTimePickerDialog', () {
    testWidgets('ダイアログを表示し、日時を返す', (WidgetTester tester) async {
      final initialDateTime = DateTime(2024, 1, 1, 10, 30);
      DateTime? selectedDateTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedDateTime = await showCustomDateTimePickerDialog(
                    context,
                    initialDateTime: initialDateTime,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                },
                child: const Text('ピッカーを開く'),
              ),
            ),
          ),
        ),
      );

      // ボタンをタップしてダイアログを開く
      await tester.tap(find.text('ピッカーを開く'));
      await tester.pumpAndSettle();

      // ダイアログが表示される
      expect(find.byType(CustomDateTimePickerDialog), findsOneWidget);

      // 確定ボタンをタップ
      await tester.tap(find.text('確定'));
      await tester.pumpAndSettle();

      // 初期値が返される
      expect(selectedDateTime, equals(initialDateTime));
    });
  });
}
