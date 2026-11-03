import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/calendar/external_calendar_usecase.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/queries/calendar/google_calendar_query_service.dart';
import 'package:memora/infrastructure/services/google_calendar_auth_service.dart';
import 'package:memora/infrastructure/services/shared_preferences_external_calendar_settings_storage.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';

final externalCalendarSupportedProvider = Provider<bool>(
  (ref) => ref.watch(appModeProvider) == AppMode.online,
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
  final auth = GoogleCalendarAuthService();
  final client = http.Client();
  ref.onDispose(client.close);
  return ExternalCalendarUsecase(
    auth,
    const SharedPreferencesExternalCalendarSettingsStorage(),
    GoogleCalendarQueryService(auth, client),
  );
});
