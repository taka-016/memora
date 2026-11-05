import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/calendar/external_calendar_usecase.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/method_channel_device_calendar_service.dart';
import 'package:memora/infrastructure/services/home_widget_calendar_cache_storage.dart';
import 'package:memora/infrastructure/services/shared_preferences_external_calendar_settings_storage.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';

final externalCalendarSupportedProvider = Provider<bool>(
  (ref) =>
      ref.watch(appModeProvider) == AppMode.online &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android,
);
final externalCalendarOwnerProvider = Provider<String?>((ref) {
  if (!ref.watch(externalCalendarSupportedProvider)) return null;
  return ref.watch(
    authNotifierProvider.select(
      (value) => value.isAuthenticated ? value.user?.id : null,
    ),
  );
});
final externalCalendarUsecaseProvider = Provider<ExternalCalendarUsecase?>((
  ref,
) {
  if (!ref.watch(externalCalendarSupportedProvider)) return null;
  const device = MethodChannelDeviceCalendarService();
  return ExternalCalendarUsecase(
    device,
    const SharedPreferencesExternalCalendarSettingsStorage(),
    device,
  );
});

final externalCalendarWidgetRefreshProvider = Provider<Future<void> Function()>(
  (ref) => const HomeWidgetCalendarCacheStorage().update,
);
