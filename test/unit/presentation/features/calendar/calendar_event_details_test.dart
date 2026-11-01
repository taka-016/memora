import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/shared/inputs/custom_search_bar.dart';
import 'package:mockito/mockito.dart';
import '../../shared/inputs/custom_search_bar_test.mocks.dart';
import '../../shared/inputs/custom_search_bar_test.dart' show mockCandidatesDefault;
import '../../../../helpers/test_exception.dart';
import 'calendar_test_support.dart';

Finder field(String label) => find.byWidgetPredicate((widget) =>
  widget is TextField && widget.decoration?.labelText == label);

Future<void> openEvent(WidgetTester tester) async {
  await tester.tap(find.byKey(calendarTestDay2));
  await tester.pump();
  await tester.tap(find.byKey(calendarTestDay2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.widgetWithText(ListTile, '予定'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('詳細を入力して保存し再表示・URL起動・解除できる', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = CalendarTestHarness();
    Uri? opened;
    await harness.pump(tester, capabilities: AppCapabilities.forMode(AppMode.offline),
      openUrl: (uri) async { opened = uri; return true; });
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (final entry in {'タイトル': '予定', 'URL': 'https://example.com',
      'メモ': '一行目\n二行目', '場所名': '集合場所'}.entries) {
      await tester.ensureVisible(field(entry.key));
      await tester.enterText(field(entry.key), entry.value);
    }
    expect(find.byType(CustomSearchBar), findsNothing);
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.savedEvents.single.memo, '一行目\n二行目');
    expect(harness.savedEvents.single.locationName, '集合場所');
    await openEvent(tester);
    expect(tester.widget<TextField>(field('メモ')).controller!.text, '一行目\n二行目');
    await tester.ensureVisible(find.byTooltip('URLを開く'));
    await tester.tap(find.byTooltip('URLを開く'));
    await tester.pump();
    expect(opened, Uri.parse('https://example.com'));
    for (final label in ['URL', 'メモ', '場所名']) {
      await tester.ensureVisible(field(label));
      await tester.enterText(field(label), '');
    }
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.savedEvents.single.url, '');
    expect(harness.savedEvents.single.memo, '');
    expect(harness.savedEvents.single.locationName, '');
  });

  testWidgets('場所の候補は名称だけを編集中の入力に反映しキャンセルで破棄する', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    addTearDown(tester.view.resetPhysicalSize);
    final search = MockSearchLocationsUsecase();
    when(search.execute(any)).thenAnswer((_) async => mockCandidatesDefault);
    final harness = CalendarTestHarness()..savedEvents.add(calendarTestEvent('event', '予定'));
    await harness.pump(tester, locationSearch: search,
      capabilities: AppCapabilities.forMode(AppMode.online));
    await openEvent(tester);
    await tester.ensureVisible(find.byType(CustomSearchBar));
    final searchField = find.descendant(of: find.byType(CustomSearchBar), matching: find.byType(TextField));
    await tester.enterText(searchField, '東京');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.ensureVisible(find.text('東京タワー'));
    await tester.tap(find.text('東京タワー'));
    await tester.pump();
    expect(tester.widget<TextField>(field('場所名')).controller!.text, '東京タワー');
    expect(harness.savedEvents.single.locationName, '');
    await tester.tap(find.text('キャンセル'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('破棄する'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CalendarEventDialog), findsNothing);
    expect(harness.savedEvents.single.locationName, '');
    await openEvent(tester);
    await tester.ensureVisible(find.byType(CustomSearchBar));
    await tester.enterText(searchField, '東京');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.ensureVisible(find.text('東京タワー'));
    await tester.tap(find.text('東京タワー'));
    await tester.pump();
    await tester.ensureVisible(field('場所名'));
    await tester.enterText(field('場所名'), '東京タワー入口');
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.savedEvents.single.locationName, '東京タワー入口');
  });

  for (final throwsError in [false, true]) {
    testWidgets('URL起動に失敗しても編集内容を保持して再試行できる（例外: $throwsError）', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      addTearDown(tester.view.resetPhysicalSize);
      var attempts = 0;
      final harness = CalendarTestHarness()..savedEvents.add(calendarTestEvent('event', '予定').copyWith(url: 'https://example.com'));
      await harness.pump(tester, openUrl: (_) async {
        attempts++;
        if (attempts > 1) return true;
        if (throwsError) throw TestException('起動失敗');
        return false;
      });
      await openEvent(tester);
      await tester.ensureVisible(find.byTooltip('URLを開く'));
      await tester.tap(find.byTooltip('URLを開く'));
      await tester.pump();
      await tester.ensureVisible(find.text('URLを開けませんでした'));
      expect(find.text('URLを開けませんでした'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('URLを開く'));
      await tester.tap(find.byTooltip('URLを開く'));
      await tester.pump();
      expect(attempts, 2);
      expect(tester.widget<TextField>(field('URL')).controller!.text, 'https://example.com');
    });
  }
}
