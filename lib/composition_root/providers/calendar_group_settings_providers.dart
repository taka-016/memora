import 'dart:io';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/services/calendar_group_initialization_policy.dart';
import 'package:memora/infrastructure/services/local_calendar_group_initialization_policy.dart';
import 'package:memora/infrastructure/services/device_calendar_membership_source.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/calendar_group_settings_storage.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/shared_preferences_calendar_group_settings_storage.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

final calendarGroupSettingsStorageProvider =
    Provider<CalendarGroupSettingsStorage>(
      (ref) => const SharedPreferencesCalendarGroupSettingsStorage(),
    );
final calendarSettingsMemberIdProvider = Provider<String?>(
  (ref) => ref.watch(currentMemberNotifierProvider).member?.id,
);
final calendarSettingsOwnerProvider = Provider<String?>((ref) {
  final mode = ref.watch(appModeProvider);
  final id = mode == AppMode.online
      ? ref.watch(authNotifierProvider).user?.id
      : ref.watch(calendarSettingsMemberIdProvider);
  return id == null ? null : '${mode.name}:$id';
});

final calendarWidgetGroupsChangedProvider = Provider<Future<void> Function()>(
  (ref) => ref.read(refreshSelectedCalendarWidgetCacheProvider),
);

final calendarGroupInitializationPolicyProvider = Provider<CalendarGroupInitializationPolicy>((ref) => LocalCalendarGroupInitializationPolicy());
final calendarGroupInitializationAllowedProvider = Provider<Future<bool> Function(String)>((ref) => (owner) async => !owner.startsWith('offline:') || await ref.read(calendarGroupInitializationPolicyProvider).canInitialize(owner));
final calendarMembershipChangesProvider = Provider<Stream<void> Function(String)?>(
  (ref) {
    if (!Platform.isAndroid) return null;
    final mode = ref.watch(appModeProvider);
    return DeviceCalendarMembershipSource(
      database: mode == AppMode.offline ? ref.watch(offlineDatabaseProvider) : null,
      firestore: mode == AppMode.online ? ref.watch(firebaseFirestoreProvider) : null,
    ).changes;
  },
);
final reloadCalendarMembershipsProvider = Provider<Future<List<GroupDto>> Function(String)>((ref) => (memberId) => ref.read(groupQueryServiceProvider).getGroupsWithMembersByMemberId(memberId));
