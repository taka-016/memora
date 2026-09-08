import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/validate_current_user_token_usecase.dart';

final validateCurrentUserTokenUseCaseProvider =
    Provider<ValidateCurrentUserTokenUseCase>((ref) {
      return ValidateCurrentUserTokenUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });
