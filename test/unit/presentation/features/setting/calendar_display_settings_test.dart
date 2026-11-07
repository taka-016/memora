import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/composition_root/providers/calendar_display_settings_providers.dart';
import 'package:memora/presentation/features/setting/calendar_display_setting.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_display_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('週の始まりと六曜を変更しウィジェットを更新して再表示時にも保持する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var updates = 0;
    final container = ProviderContainer(
      overrides: [
        updateCalendarWidgetAppearanceProvider.overrideWithValue(() async {
          updates++;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CalendarDisplaySetting()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('日曜日'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('calendar_week_start_setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月曜日').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('六曜を表示'));
    await tester.pumpAndSettle();
    expect(updates, 2);
    final saved = await const SharedPreferencesCalendarDisplaySettingsStorage()
        .load();
    expect(
      saved,
      const CalendarDisplaySettings(
        weekStart: CalendarWeekStart.monday,
        showRokuyo: true,
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CalendarDisplaySetting()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('月曜日'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });
}
