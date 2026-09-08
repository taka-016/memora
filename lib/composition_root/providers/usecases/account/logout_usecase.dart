import 'package:memora/composition_root/providers/services/android_widget_cache_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(
    authService: ref.watch(authServiceProvider),
    androidWidgetCacheStorage: ref.watch(androidWidgetCacheStorageProvider),
  );
});
