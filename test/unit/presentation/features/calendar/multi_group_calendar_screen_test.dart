import 'package:mockito/mockito.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
import 'package:memora/composition_root/providers/group_providers.dart';
import '../../../../helpers/calendar_group_test_support.dart';
import '../../notifiers/calendar/calendar_notifier_test.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora/application/models/calendar_group_settings.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_group_settings_notifier.dart';
import 'package:memora/presentation/features/calendar/calendar_screen.dart';
import 'package:memora/presentation/features/calendar/calendar_event_dialog.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifier.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_state.dart';
import 'package:memora/composition_root/providers/calendar_group_settings_providers.dart';
import 'package:memora/composition_root/providers/external_calendar_providers.dart';

class _Settings extends CalendarGroupSettingsNotifier {
  @override
  CalendarGroupSettingsState build() => CalendarGroupSettingsState(isLoading: false, groupsReady: true, groups: const [GroupDto(id: 'g', ownerId: 'self', name: '家族', members: [])]);
  @override
  Future<bool> setVisibleGroups(Set<String> ids) async { state = state.copyWith(settings: CalendarGroupSettings(visibleGroupIds: ids)); return true; }
}
class _Calendar extends CalendarNotifier {
  @override
  CalendarState build(String groupId) => CalendarState(selectedDate: DateTime(2026, 11, 14), group: const GroupDto(id: 'g', ownerId: 'self', name: '家族', members: []), hasLoadedLabels: true);
  @override
  Future<void> load() async {}
}
class _LoadingSettings extends _Settings {
  @override
  CalendarGroupSettingsState build() => super.build().copyWith(isLoading: true);
  void finish() => state = state.copyWith(isLoading: false, settings: CalendarGroupSettings(defaultGroupId: 'g'));
}
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('設定取得完了まで追加要求を待ち保存済み既定グループで開く', (tester) async {
    final settings = _LoadingSettings();
    final labels = MockGetCalendarLabelsUsecase();
    when(labels.execute(any)).thenAnswer((_) async => []);
    await tester.pumpWidget(ProviderScope(overrides: [
      calendarSettingsOwnerProvider.overrideWithValue('online:self'),
      calendarGroupSettingsNotifierProvider.overrideWith(() => settings),
      externalCalendarSupportedProvider.overrideWithValue(false),
      getGroupWithMembersByIdUsecaseProvider.overrideWithValue(calendarTestGroupLoader()),
      getCalendarLabelsUsecaseProvider.overrideWithValue(labels),
    ], child: const MaterialApp(home: Scaffold(body: CalendarScreen(createEvent: true)))));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventDialog), findsNothing);
    expect(tester.widget<FloatingActionButton>(find.byType(FloatingActionButton)).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == '表示グループの選択')).onPressed, isNull);
    settings.finish();
    await tester.pumpAndSettle();
    expect(find.byType(CalendarEventDialog), findsOneWidget);
    final group = tester.widget<DropdownButtonFormField<String>>(find.byWidgetPredicate((w) => w is DropdownButtonFormField<String> && w.decoration.labelText == '保存先グループ'));
    expect(group.initialValue, 'g');
  });
  testWidgets('所属1件でも自動選択せず表示選択のキャンセル・確定・全解除を扱う', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      calendarSettingsOwnerProvider.overrideWithValue('online:self'),
      calendarGroupSettingsNotifierProvider.overrideWith(_Settings.new),
      externalCalendarSupportedProvider.overrideWithValue(false),
      calendarNotifierProvider('g').overrideWith(_Calendar.new),
    ], child: const MaterialApp(home: Scaffold(body: CalendarScreen()))));
    await tester.pump();
    expect(find.text('表示するグループを選択してください'), findsOneWidget);
    await tester.tap(find.byTooltip('表示グループの選択')); await tester.pumpAndSettle();
    await tester.tap(find.text('家族')); await tester.tap(find.text('キャンセル')); await tester.pumpAndSettle();
    expect(find.text('表示するグループを選択してください'), findsOneWidget);
    await tester.tap(find.byTooltip('表示グループの選択')); await tester.pumpAndSettle();
    await tester.tap(find.text('家族')); await tester.tap(find.text('確定')); await tester.pumpAndSettle();
    expect(find.text('表示するグループを選択してください'), findsNothing);
    await tester.tap(find.byTooltip('予定を追加')); await tester.pumpAndSettle();
    expect(find.byType(CalendarEventDialog), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存')).onPressed, isNull);
    await tester.tap(find.text('キャンセル')); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('表示グループの選択')); await tester.pumpAndSettle();
    await tester.tap(find.text('全解除')); await tester.tap(find.text('確定')); await tester.pumpAndSettle();
    expect(find.text('表示するグループを選択してください'), findsOneWidget);
  });
}
