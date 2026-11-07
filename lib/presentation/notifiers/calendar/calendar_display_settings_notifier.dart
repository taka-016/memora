import 'package:memora/application/models/calendar_display_settings.dart';
import 'package:memora/composition_root/providers/calendar_display_settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_display_settings_notifier.g.dart';

class CalendarDisplaySettingsState {
  const CalendarDisplaySettingsState({
    required this.settings,
    this.isSaving = false,
  });
  final CalendarDisplaySettings settings;
  final bool isSaving;
}

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(keepAlive: true, retry: _noRetry)
class CalendarDisplaySettingsNotifier
    extends _$CalendarDisplaySettingsNotifier {
  @override
  Future<CalendarDisplaySettingsState> build() async =>
      CalendarDisplaySettingsState(
        settings: await ref
            .watch(calendarDisplaySettingsStorageProvider)
            .load(),
      );

  Future<bool> save(CalendarDisplaySettings settings) async {
    final previous = state.value;
    if (previous == null || previous.isSaving) return false;
    if (previous.settings == settings) return true;
    state = AsyncData(
      CalendarDisplaySettingsState(settings: previous.settings, isSaving: true),
    );
    try {
      await ref.read(calendarDisplaySettingsStorageProvider).save(settings);
    } catch (_) {
      if (ref.mounted) state = AsyncData(previous);
      return false;
    }
    if (!ref.mounted) return true;
    state = AsyncData(
      CalendarDisplaySettingsState(settings: settings, isSaving: true),
    );
    try {
      await ref.read(updateCalendarWidgetAppearanceProvider)();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (ref.mounted)
        state = AsyncData(CalendarDisplaySettingsState(settings: settings));
    }
  }
}
