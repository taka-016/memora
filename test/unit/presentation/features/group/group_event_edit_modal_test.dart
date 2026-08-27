import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';

import '../../../../helpers/test_exception.dart';

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
          onSave: (_) async => throw TestException('保存失敗'),
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

    testWidgets('保存中に保存ボタンを連続操作しても重複実行しない', (tester) async {
      final completer = Completer<void>();
      var callCount = 0;
      await tester.pumpWidget(
        buildSubject(
          onSave: (_) {
            callCount++;
            return completer.future;
          },
          selectedYear: 2026,
          initialMemo: '',
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      final saveButton = find.byKey(const Key('group_event_save_button_2026'));

      await tester.tap(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pump();

      expect(callCount, 1);
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('保存中はバリアタップと戻る操作で閉じない', (tester) async {
      final completer = Completer<void>();
      addTearDown(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await tester.pumpWidget(
        buildSubject(
          onSave: (_) => completer.future,
          selectedYear: 2026,
          initialMemo: '',
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      const dialogKey = Key('group_event_edit_dialog_2026');

      await tester.tap(find.byKey(const Key('group_event_save_button_2026')));
      await tester.pump();
      await tester.tapAt(const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(dialogKey), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(dialogKey), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(dialogKey), findsNothing);
    });
  });
}
