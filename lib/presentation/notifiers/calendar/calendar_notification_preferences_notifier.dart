import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memora/application/services/calendar/calendar_notification_preferences.dart';
import 'package:memora/composition_root/providers/calendar_notification_providers.dart';
import 'package:memora/presentation/notifiers/calendar/calendar_notifications_notifier.dart';
part 'calendar_notification_preferences_notifier.g.dart';

class CalendarNotificationPreferencesState {
  const CalendarNotificationPreferencesState(
    this.preferences, {
    this.isSaving = false,
  });
  final CalendarNotificationPreferences preferences;
  final bool isSaving;
}

@Riverpod(keepAlive: true)
class CalendarNotificationPreferencesNotifier
    extends _$CalendarNotificationPreferencesNotifier {
  @override
  Future<CalendarNotificationPreferencesState> build() async =>
      CalendarNotificationPreferencesState(
        await ref.read(calendarNotificationStorageProvider).load(),
      );

  Future<bool> save(CalendarNotificationPreferences preferences) async {
    final previous = state.value;
    if (previous == null || previous.isSaving) return false;
    state = AsyncData(
      CalendarNotificationPreferencesState(
        previous.preferences,
        isSaving: true,
      ),
    );
    try {
      await ref.read(calendarNotificationStorageProvider).save(preferences);
      if (!ref.mounted) return true;
      state = AsyncData(CalendarNotificationPreferencesState(preferences));
      if (ref.exists(calendarNotificationsNotifierProvider)) {
        await ref
            .read(calendarNotificationsNotifierProvider.notifier)
            .refresh();
      }
      return true;
    } catch (_) {
      if (ref.mounted) state = AsyncData(previous);
      return false;
    }
  }
}
