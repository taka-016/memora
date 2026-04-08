import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';

void main() {
  group('showGroupEventEditModal', () {
    Widget buildSubject({
      required Future<void> Function(String memo) onSave,
      required int selectedYear,
      required String initialMemo,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showGroupEventEditModal(
                    context: context,
                    selectedYear: selectedYear,
                    initialMemo: initialMemo,
                    onSave: onSave,
                  );
                },
                child: const Text('開く'),
              );
            },
          ),
        ),
      );
    }

    testWidgets('初期値と既存Keyを維持したまま表示できる', (tester) async {
      const selectedYear = 2026;

      await tester.pumpWidget(
        buildSubject(
          onSave: (_) async {},
          selectedYear: selectedYear,
          initialMemo: '運動会',
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('group_event_edit_dialog_2026')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('group_event_edit_field_2026')),
        findsOneWidget,
      );

      final textField = tester.widget<TextField>(
        find.byKey(const Key('group_event_edit_field_2026')),
      );
      expect(textField.controller?.text, '運動会');
    });

    testWidgets('保存時は前後空白を除去してonSaveを呼ぶ', (tester) async {
      String? savedMemo;

      await tester.pumpWidget(
        buildSubject(
          onSave: (memo) async {
            savedMemo = memo;
          },
          selectedYear: 2026,
          initialMemo: '',
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('group_event_edit_field_2026')),
        '  太郎の運動会  ',
      );

      await tester.tap(find.byKey(const Key('group_event_save_button_2026')));
      await tester.pumpAndSettle();

      expect(savedMemo, '太郎の運動会');
      expect(
        find.byKey(const Key('group_event_edit_dialog_2026')),
        findsNothing,
      );
    });

    testWidgets('保存失敗時はSnackBarでフィードバックする', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          onSave: (_) async => throw Exception('保存失敗'),
          selectedYear: 2026,
          initialMemo: '',
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('group_event_save_button_2026')));
      await tester.pump();

      expect(find.text('グループイベントの保存に失敗しました'), findsOneWidget);
      expect(
        find.byKey(const Key('group_event_edit_dialog_2026')),
        findsOneWidget,
      );
    });
  });
}
