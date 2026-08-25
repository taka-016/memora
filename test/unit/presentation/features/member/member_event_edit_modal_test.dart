import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/member/member_event_edit_modal.dart';

void main() {
  testWidgets('保存中に保存ボタンを連続操作しても重複実行しない', (tester) async {
    final completer = Completer<void>();
    var callCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showMemberEventEditModal(
                  context: context,
                  memberId: 'member-1',
                  memberName: '太郎',
                  selectedYear: 2026,
                  initialMemo: '',
                  onSave: (_) {
                    callCount++;
                    return completer.future;
                  },
                );
              },
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    final saveButton = find.byKey(
      const Key('member_event_save_button_member-1_2026'),
    );

    await tester.tap(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    expect(callCount, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });
}
