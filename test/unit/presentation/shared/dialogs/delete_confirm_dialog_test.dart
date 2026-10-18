import 'dart:async';

import '../../../../helpers/test_exception.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/shared/dialogs/delete_confirm_dialog.dart';

void main() {
  group('DeleteConfirmDialog', () {
    for (final fails in [false, true]) {
      testWidgets('showが削除完了を待って${fails ? '例外を伝える' : '結果を返す'}', (tester) async {
        final pending = Completer<void>();
        var completed = false;
        Object? error;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    try {
                      await DeleteConfirmDialog.show(
                        context,
                        title: '確認',
                        content: '削除しますか',
                        onConfirm: () => pending.future,
                      );
                    } catch (e) {
                      error = e;
                    }
                    completed = true;
                  },
                  child: const Text('開く'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('開く'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('削除'));
        await tester.pumpAndSettle();
        expect(completed, isFalse);
        final failure = TestException('削除拒否');
        if (fails) {
          pending.completeError(failure);
        } else {
          pending.complete();
        }
        await tester.pump();
        expect(completed, isTrue);
        expect(error, fails ? same(failure) : isNull);
      });
    }

    testWidgets('削除確認ダイアログが表示されること', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteConfirmDialog(
              title: 'テスト削除',
              content: 'テストアイテムを削除しますか？',
              onConfirm: () {},
            ),
          ),
        ),
      );

      expect(find.text('テスト削除'), findsOneWidget);
      expect(find.text('テストアイテムを削除しますか？'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('キャンセルボタンを押したときfalseが返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => DeleteConfirmDialog(
                      title: 'テスト削除',
                      content: 'テストアイテムを削除しますか？',
                      onConfirm: () {},
                    ),
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

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('削除ボタンを押したときtrueが返ること', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (context) => DeleteConfirmDialog(
                      title: 'テスト削除',
                      content: 'テストアイテムを削除しますか？',
                      onConfirm: () {},
                    ),
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

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('showメソッドでonConfirmが呼ばれること', (WidgetTester tester) async {
      bool confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await DeleteConfirmDialog.show(
                    context,
                    title: 'テスト削除',
                    content: 'テストアイテムを削除しますか？',
                    onConfirm: () {
                      confirmCalled = true;
                    },
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

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(confirmCalled, true);
    });
  });
}
