import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/application/services/calendar_display_settings_storage.dart';
import 'package:memora/composition_root/providers/calendar_display_settings_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_display_settings_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'calendar_display_settings_notifier_test.mocks.dart';

@GenerateMocks([CalendarDisplaySettingsStorage])
void main() {
  const initial = CalendarDisplaySettings();
  const selected = CalendarDisplaySettings(
    weekStart: CalendarWeekStart.monday,
    showRokuyo: true,
  );
  late MockCalendarDisplaySettingsStorage storage;
  late ProviderContainer container;
  var updates = 0;

  setUp(() {
    updates = 0;
    storage = MockCalendarDisplaySettingsStorage();
    when(storage.load()).thenAnswer((_) async => initial);
    container = ProviderContainer(
      overrides: [
        calendarDisplaySettingsStorageProvider.overrideWithValue(storage),
        updateCalendarWidgetAppearanceProvider.overrideWithValue(() async {
          updates++;
        }),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('保存失敗時は元の設定を保持し再試行できる', () async {
    await container.read(calendarDisplaySettingsNotifierProvider.future);
    final notifier = container.read(
      calendarDisplaySettingsNotifierProvider.notifier,
    );
    when(storage.save(selected)).thenThrow(TestException('保存失敗'));
    expect(await notifier.save(selected), isFalse);
    expect(
      container.read(calendarDisplaySettingsNotifierProvider).value!.settings,
      initial,
    );
    expect(updates, 0);
    when(storage.save(selected)).thenAnswer((_) async {});
    expect(await notifier.save(selected), isTrue);
    expect(
      container.read(calendarDisplaySettingsNotifierProvider).value!.settings,
      selected,
    );
    expect(updates, 1);
  });

  test('保存中の別操作を開始せず保存完了後にウィジェットへ反映する', () async {
    await container.read(calendarDisplaySettingsNotifierProvider.future);
    final notifier = container.read(
      calendarDisplaySettingsNotifierProvider.notifier,
    );
    final pending = Completer<void>();
    when(storage.save(selected)).thenAnswer((_) => pending.future);
    final saving = notifier.save(selected);
    expect(
      container.read(calendarDisplaySettingsNotifierProvider).value!.isSaving,
      isTrue,
    );
    expect(await notifier.save(selected.copyWith(showRokuyo: false)), isFalse);
    expect(updates, 0);
    pending.complete();
    expect(await saving, isTrue);
    expect(updates, 1);
    expect(
      container.read(calendarDisplaySettingsNotifierProvider).value!.isSaving,
      isFalse,
    );
  });

  test('ウィジェット更新が失敗しても保存済みの設定を表示する', () async {
    container.dispose();
    container = ProviderContainer(
      overrides: [
        calendarDisplaySettingsStorageProvider.overrideWithValue(storage),
        updateCalendarWidgetAppearanceProvider.overrideWithValue(() async {
          throw TestException('更新失敗');
        }),
      ],
    );
    await container.read(calendarDisplaySettingsNotifierProvider.future);
    when(storage.save(selected)).thenAnswer((_) async {});
    expect(
      await container
          .read(calendarDisplaySettingsNotifierProvider.notifier)
          .save(selected),
      isFalse,
    );
    final state = container
        .read(calendarDisplaySettingsNotifierProvider)
        .value!;
    expect(state.settings, selected);
    expect(state.isSaving, isFalse);
    verify(storage.save(selected)).called(1);
  });
}
