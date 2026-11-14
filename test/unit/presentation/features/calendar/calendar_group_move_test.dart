import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/dtos/calendar/calendar_event_dto.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'calendar_test_support.dart';
import 'calendar_event_details_test.dart' show field, openEvent;
import '../../notifiers/calendar/calendar_mutation_coordinator_test.mocks.dart';
import '../../../../helpers/test_exception.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('非表示グループへの移動を確認しキャンセルと失敗では入力を保持する', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final move = MockMoveCalendarEventUsecase();
    final harness = CalendarTestHarness()..savedEvents.add(calendarTestEvent('event', '予定'));
    await harness.pump(tester, move: move);
    await openEvent(tester);
    await tester.enterText(field('タイトル'), '入力中');
    await tester.tap(find.byWidgetPredicate((w) => w is DropdownButtonFormField<String> && w.decoration.labelText == '保存先グループ'));
    await tester.pumpAndSettle(); await tester.tap(find.text('友人').last); await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存')); await tester.tap(find.text('保存')); await tester.pumpAndSettle();
    expect(find.text('保存先の確認'), findsOneWidget);
    expect(find.textContaining('表示から外れます'), findsOneWidget);
    await tester.tap(find.text('キャンセル').last); await tester.pumpAndSettle();
    verifyNever(move.execute(any, any, any));
    expect(tester.widget<TextField>(field('タイトル')).controller!.text, '入力中');
    when(move.execute(any, any, any)).thenThrow(TestException('保存失敗'));
    await tester.tap(find.text('保存')); await tester.pumpAndSettle();
    await tester.tap(find.text('保存する')); await tester.pumpAndSettle();
    expect(find.byType(CalendarEventDialog), findsOneWidget);
    expect(tester.widget<TextField>(field('タイトル')).controller!.text, '入力中');
    when(move.execute(any, any, any)).thenAnswer((_) async {});
    await tester.tap(find.text('保存')); await tester.pumpAndSettle(); await tester.tap(find.text('保存する')); await tester.pumpAndSettle();
    final input = verify(move.execute(any, captureAny, any)).captured.last as CalendarEventDto;
    expect(input.groupId, 'g2'); expect(input.labelType, 'group'); expect(input.title, '入力中');
    expect(find.byType(CalendarEventDialog), findsNothing);
  });
}
