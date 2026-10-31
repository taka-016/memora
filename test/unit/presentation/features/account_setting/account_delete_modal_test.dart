import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/account_setting/account_delete_modal.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  group('AccountDeleteModal', () {
    Widget createTestWidget({
      required Future<bool> Function() onAccountDelete,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      AccountDeleteModal(onAccountDelete: onAccountDelete),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('ダーク時の削除処理中も進行表示が見えて二重実行を防ぐ', (tester) async {
      final completion = Completer<bool>();
      var calls = 0;
      await tester.pumpWidget(
        createTestWidget(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.lightBlue,
              brightness: Brightness.dark,
            ),
          ),
          onAccountDelete: () {
            calls++;
            return completion.future;
          },
        ),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除'));
      await tester.pump();
      final progressFinder = find.byType(CircularProgressIndicator);
      final progress = tester.widget<CircularProgressIndicator>(progressFinder);
      final buttonFinder = find.ancestor(
        of: progressFinder,
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(buttonFinder);
      final context = tester.element(buttonFinder);
      final theme = Theme.of(context);
      const states = {WidgetState.disabled};
      final style = button.style!;
      final background =
          style.backgroundColor?.resolve(states) ??
          button.defaultStyleOf(context).backgroundColor!.resolve(states)!;
      final surface = theme.colorScheme.surfaceContainerHigh;
      final effectiveBackground = Color.alphaBlend(background, surface);
      final foreground = progress.color ?? theme.colorScheme.primary;
      final a = foreground.computeLuminance();
      final b = effectiveBackground.computeLuminance();
      expect(
        a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05),
        greaterThanOrEqualTo(3),
      );
      expect(button.onPressed, isNull);
      await tester.tap(progressFinder);
      expect(calls, 1);
      completion.complete(false);
      await tester.pump();
      expect(progressFinder, findsNothing);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('アカウント削除ダイアログの基本要素が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(onAccountDelete: () async => true),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('アカウント削除'), findsOneWidget);
      expect(
        find.text(
          'アカウントを削除すると、すべてのデータが完全に削除されます。\n'
          'この操作は取り消すことができません。\n\n'
          '本当にアカウントを削除しますか？',
        ),
        findsOneWidget,
      );
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('削除ボタンをタップするとコールバックが実行される', (WidgetTester tester) async {
      var isCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          onAccountDelete: () async {
            isCalled = true;
            return true;
          },
        ),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(isCalled, isTrue);
    });

    testWidgets('キャンセルボタンをタップするとダイアログが閉じる', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(onAccountDelete: () async => true),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountDeleteModal), findsNothing);
    });

    testWidgets('削除ボタンはテーマの警告色と対応する文字色で表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(onAccountDelete: () async => true),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final deleteButton = find.widgetWithText(ElevatedButton, '削除');
      expect(deleteButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(deleteButton);
      final scheme = Theme.of(tester.element(deleteButton)).colorScheme;
      expect(button.style?.backgroundColor?.resolve({}), scheme.error);
      expect(button.style?.foregroundColor?.resolve({}), scheme.onError);
    });

    testWidgets('エラー発生時はダイアログが閉じない', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          onAccountDelete: () async {
            throw TestException('削除に失敗しました');
          },
        ),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pump();

      expect(find.byType(AccountDeleteModal), findsOneWidget);
    });
  });
}
