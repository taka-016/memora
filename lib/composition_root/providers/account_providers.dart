import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/account/delete_user_usecase.dart';
import 'package:memora/application/usecases/account/get_current_user_usecase.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';
import 'package:memora/application/usecases/account/logout_usecase.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';
import 'package:memora/application/usecases/account/reauthenticate_usecase.dart';
import 'package:memora/application/usecases/account/send_email_verification_usecase.dart';
import 'package:memora/application/usecases/account/signup_usecase.dart';
import 'package:memora/application/usecases/account/update_email_usecase.dart';
import 'package:memora/application/usecases/account/update_password_usecase.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';
import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final deleteUserUseCaseProvider = Provider<DeleteUserUseCase>((ref) {
  return DeleteUserUseCase(authService: ref.watch(authServiceProvider));
});

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

final reauthenticateUseCaseProvider = Provider<ReauthenticateUseCase>((ref) {
  return ReauthenticateUseCase(authService: ref.watch(authServiceProvider));
});

final sendEmailVerificationUseCaseProvider =
    Provider<SendEmailVerificationUseCase>((ref) {
      return SendEmailVerificationUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(authService: ref.watch(authServiceProvider));
});

final updateEmailUseCaseProvider = Provider<UpdateEmailUseCase>((ref) {
  return UpdateEmailUseCase(authService: ref.watch(authServiceProvider));
});

final updatePasswordUseCaseProvider = Provider<UpdatePasswordUseCase>((ref) {
  return UpdatePasswordUseCase(authService: ref.watch(authServiceProvider));
});

final validateCurrentUserTokenUseCaseProvider =
    Provider<ValidateCurrentUserTokenUseCase>((ref) {
      return ValidateCurrentUserTokenUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });
