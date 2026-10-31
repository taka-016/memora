import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/composition_root/providers/calendar_providers.dart';
part 'calendar_preferences_notifier.g.dart';

class CalendarPreferencesState {
  const CalendarPreferencesState({
    required this.minutes,
    this.isSaving = false,
  });
  final int minutes;
  final bool isSaving;
}

@riverpod
class CalendarPreferencesNotifier extends _$CalendarPreferencesNotifier {
  @override
  Future<CalendarPreferencesState> build() async => CalendarPreferencesState(
    minutes: await ref.read(calendarDefaultDurationStorageProvider).load(),
  );
  Future<bool>? _pendingSave;

  Future<bool> save(int minutes) async {
    if (minutes < 1 || minutes > 1440) return false;
    final link = ref.keepAlive();
    final operation = _saveAfter(_pendingSave, minutes);
    _pendingSave = operation;
    try {
      return await operation;
    } finally {
      if (identical(_pendingSave, operation)) _pendingSave = null;
      link.close();
    }
  }

  Future<bool> _saveAfter(Future<bool>? pending, int minutes) async {
    if (pending != null) await pending;
    if (!ref.mounted) return false;
    return await _persist(minutes);
  }

  Future<bool> _persist(int minutes) async {
    final previous = state.value;
    if (previous == null ||
        previous.isSaving ||
        minutes < 1 ||
        minutes > 1440) {
      return false;
    }
    state = AsyncData(
      CalendarPreferencesState(minutes: previous.minutes, isSaving: true),
    );
    try {
      await ref.read(calendarDefaultDurationStorageProvider).save(minutes);
      if (ref.mounted) {
        state = AsyncData(CalendarPreferencesState(minutes: minutes));
      }
      return true;
    } catch (_) {
      if (ref.mounted) state = AsyncData(previous);
      return false;
    }
  }
}
