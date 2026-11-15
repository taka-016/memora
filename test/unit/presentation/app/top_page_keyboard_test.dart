import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/app/app_routes.dart';
import 'package:memora/presentation/app/top_page.dart';

import 'top_page_test_support.dart';

void main() {
  final context = TopPageTestContext();
  setUp(context.setUpContext);

  for (final location in [
    const GroupListRoute().location,
    const AccountSettingsRoute().location,
  ]) {
    testWidgets('$locationではダイアログ入力中も背後の表示領域を維持し閉じるとキーボード回避に戻る', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        context.createTestWidget(initialLocation: location),
      );
      await tester.pumpAndSettle();

      final backgroundScaffold = find
          .descendant(of: find.byType(TopPage), matching: find.byType(Scaffold))
          .last;
      Rect backgroundBounds() {
        final scaffold = tester.widget<Scaffold>(backgroundScaffold);
        return tester.getRect(find.byWidget(scaffold.body!));
      }

      final initialBounds = backgroundBounds();
      unawaited(
        showDialog<void>(
          context: tester.element(backgroundScaffold),
          builder: (dialogContext) => AlertDialog(
            title: const Text('入力'),
            content: const TextField(),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '入力内容');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(backgroundBounds(), initialBounds);
      expect(find.text('入力内容'), findsOneWidget);
      expect(tester.getRect(find.text('閉じる')).bottom, lessThanOrEqualTo(700));
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(backgroundBounds().height, lessThan(initialBounds.height));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(backgroundBounds(), initialBounds);
      expect(tester.takeException(), isNull);
    });
  }
}
