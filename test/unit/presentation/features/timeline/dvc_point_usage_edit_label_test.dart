import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/timeline/dvc_point_usage_edit_label.dart';

void main() {
  group('DvcPointUsageEditLabel', () {
    testWidgets('DVCラベルと編集ボタンを表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DvcPointUsageEditLabel(onPressed: () {})),
        ),
      );

      expect(find.text('DVC'), findsOneWidget);
      expect(
        find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('編集ボタン押下時にコールバックを呼ぶ', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DvcPointUsageEditLabel(
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const Key('timeline_dvc_point_usage_edit_button')),
      );

      expect(tapped, isTrue);
    });
  });
}
