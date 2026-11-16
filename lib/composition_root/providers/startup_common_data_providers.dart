import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/services/startup_common_data_source.dart';
import 'package:memora/application/services/startup_common_data_storage.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/infrastructure/services/firestore_startup_common_data_source.dart';
import 'package:memora/infrastructure/services/shared_preferences_startup_common_data_storage.dart';
import 'package:memora/presentation/notifiers/auth/auth_notifier.dart';
import 'package:memora/presentation/notifiers/member/current_member_notifier.dart';

final startupCommonDataOwnerProvider = Provider<String?>((ref) {
  if (ref.watch(appModeProvider) != AppMode.online) return null;
  final auth = ref.watch(authNotifierProvider);
  return auth.isAuthenticated ? auth.user?.id : null;
});
final startupCommonDataMemberIdProvider = Provider<String?>(
  (ref) => ref.watch(currentMemberNotifierProvider).member?.id,
);
final startupCommonDataStorageProvider = Provider<StartupCommonDataStorage>(
  (ref) => const SharedPreferencesStartupCommonDataStorage(),
);
final startupCommonDataSourceProvider = Provider<StartupCommonDataSource>(
  (ref) =>
      FirestoreStartupCommonDataSource(ref.watch(firebaseFirestoreProvider)),
);
