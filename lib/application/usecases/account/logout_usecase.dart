import 'package:memora/application/services/android_widget_cache_storage.dart';
import 'package:memora/application/services/auth_service.dart';

class LogoutUseCase {
  const LogoutUseCase({
    required this.authService,
    this.androidWidgetCacheStorage,
  });

  final AuthService authService;
  final AndroidWidgetCacheStorage? androidWidgetCacheStorage;

  Future<void> execute() async {
    await androidWidgetCacheStorage?.clear();
    await androidWidgetCacheStorage?.updateWidget();
    await authService.signOut();
  }
}
