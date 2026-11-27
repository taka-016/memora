import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/composition_root/factories/auth_service_factory.dart';

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(authService: ref.watch(authServiceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(authService: ref.watch(authServiceProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(
    authService: ref.watch(authServiceProvider),
    androidWidgetCacheStorage: ref.watch(androidWidgetCacheStorageProvider),
  );
});

final observeAuthStateChangesUseCaseProvider =
    Provider<ObserveAuthStateChangesUseCase>((ref) {
      return ObserveAuthStateChangesUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });
