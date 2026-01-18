import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/dialogs/edit_discard_confirm_dialog.dart';

void main() {
  group('EditDiscardConfirmDialog', () {
    testWidgets('編集破棄確認ダイアログが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EditDiscardConfirmDialog())),
      );

      expect(find.text('変更内容の確認'), findsOneWidget);
      expect(find.text('変更内容が保存されていません。破棄しますか？'), findsOneWidget);
      expect(find.text('編集を続ける'), findsOneWidget);
      expect(find.text('破棄する'), findsOneWidget);
    });

    testWidgets('編集を続けるボタンを押したときfalseが返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const EditDiscardConfirmDialog(),
                  );
                },
                child: const Text('ダイアログ表示'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('編集を続ける'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('破棄するボタンを押したときtrueが返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => const EditDiscardConfirmDialog(),
                  );
                },
                child: const Text('ダイアログ表示'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('破棄する'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('showメソッドで破棄操作がtrueで返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await EditDiscardConfirmDialog.show(context);
                },
                child: const Text('ダイアログ表示'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('破棄する'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('showメソッドで編集を続ける操作がfalseで返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await EditDiscardConfirmDialog.show(context);
                },
                child: const Text('ダイアログ表示'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('編集を続ける'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('showメソッドでダイアログを閉じたときデフォルト値falseが返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await EditDiscardConfirmDialog.show(context);
                },
                child: const Text('ダイアログ表示'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ダイアログ表示'));
      await tester.pumpAndSettle();

      // ダイアログ外をタップして閉じる
      await tester.tapAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(result, false);
    });
  });
}
