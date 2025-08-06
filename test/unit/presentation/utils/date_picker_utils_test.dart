import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/utils/date_picker_utils.dart';

void main() {
  group('DatePickerUtils', () {
    testWidgets('showCustomDatePicker カスタムテーマでDatePickerが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('date_picker_button'),
                  onPressed: () async {
                    await DatePickerUtils.showCustomDatePicker(
                      context,
                      initialDate: DateTime(2024, 1, 15),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                  },
                  child: const Text('日付選択'),
                );
              },
            ),
          ),
        ),
      );

      // ボタンをタップしてDatePickerを開く
      await tester.tap(find.byKey(const Key('date_picker_button')));
      await tester.pumpAndSettle();

      // CustomDatePickerDialogが表示されることを確認
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('showCustomDatePicker パラメータが正しく渡される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('date_picker_button'),
                  onPressed: () async {
                    await DatePickerUtils.showCustomDatePicker(
                      context,
                      initialDate: DateTime(2024, 1, 15),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                  },
                  child: const Text('日付選択'),
                );
              },
            ),
          ),
        ),
      );

      // ボタンをタップしてDatePickerを開く
      await tester.tap(find.byKey(const Key('date_picker_button')));
      await tester.pumpAndSettle();

      // DatePickerが正常に表示されることを確認
      expect(find.byType(Dialog), findsOneWidget);

      // 初期日付の15日が表示されることを確認
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('showCustomDatePicker キャンセル時にnullが返される', (tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('date_picker_button'),
                  onPressed: () async {
                    selectedDate = await DatePickerUtils.showCustomDatePicker(
                      context,
                      initialDate: DateTime(2024, 1, 15),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                  },
                  child: const Text('日付選択'),
                );
              },
            ),
          ),
        ),
      );

      // ボタンをタップしてDatePickerを開く
      await tester.tap(find.byKey(const Key('date_picker_button')));
      await tester.pumpAndSettle();

      // ダイアログの外側をタップしてキャンセル
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // nullが返されることを確認
      expect(selectedDate, isNull);
    });

    testWidgets(
      'showCustomDatePicker initialDate、firstDate、lastDateが正しく設定される',
      (tester) async {
        final initialDate = DateTime(2023, 6, 15);
        final firstDate = DateTime(2020);
        final lastDate = DateTime(2030);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    key: const Key('date_picker_button'),
                    onPressed: () async {
                      await DatePickerUtils.showCustomDatePicker(
                        context,
                        initialDate: initialDate,
                        firstDate: firstDate,
                        lastDate: lastDate,
                      );
                    },
                    child: const Text('日付選択'),
                  );
                },
              ),
            ),
          ),
        );

        // ボタンをタップしてDatePickerを開く
        await tester.tap(find.byKey(const Key('date_picker_button')));
        await tester.pumpAndSettle();

        // DatePickerが表示され、初期日付が正しく表示されることを確認
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('15'), findsOneWidget); // 初期日付の日が表示される
      },
    );
  });
}
