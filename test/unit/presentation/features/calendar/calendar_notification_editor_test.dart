import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/presentation/features/calendar/calendar_notification_editor.dart';

void main() {
  testWidgets('通知を追加・解除し、最大5件で追加操作を止める', (tester) async {
    var values = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) => CalendarNotificationEditor(
              allDay: true,
              values: values,
              onChanged: (next) => update(() => values = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('通知を追加'));
    await tester.pump();
    await tester.tap(find.text('予定の開始時').last);
    await tester.pump();
    expect(values, [0]);
    await tester.tap(find.byTooltip('通知を解除'));
    await tester.pump();
    expect(values, isEmpty);
    for (final label in ['予定の開始時', '1日前', '2日前', '1週間前', '2週間前']) {
      await tester.tap(find.text('通知を追加'));
      await tester.pump();
      await tester.tap(find.text(label).last);
      await tester.pump();
    }
    expect(values, hasLength(5));
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '通知を追加'))
          .onPressed,
      isNull,
    );
  });
}
