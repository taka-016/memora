import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/android_widget_cache_storage_factory.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(
    authService: ref.watch(authServiceProvider),
    androidWidgetCacheStorage: ref.watch(androidWidgetCacheStorageProvider),
  );
});

class LogoutUseCase {
  const LogoutUseCase({
    required this.authService,
    this.androidWidgetCacheStorage,
  });

  final AuthService authService;
  final AndroidWidgetCacheStorage? androidWidgetCacheStorage;

  Future<void> execute() async {
    await androidWidgetCacheStorage?.clear();
    await authService.signOut();
  }
}
