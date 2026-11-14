import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_group_settings_storage.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

final calendarGroupSettingsStorageProvider = Provider<CalendarGroupSettingsStorage>((ref) => const SharedPreferencesCalendarGroupSettingsStorage());
final calendarSettingsMemberIdProvider = Provider<String?>((ref) => ref.watch(currentMemberNotifierProvider).member?.id);
final calendarSettingsOwnerProvider = Provider<String?>((ref) {
  final mode = ref.watch(appModeProvider);
  final id = mode == AppMode.online
    ? ref.watch(authNotifierProvider).user?.id
    : ref.watch(calendarSettingsMemberIdProvider);
  return id == null ? null : '${mode.name}:$id';
});
