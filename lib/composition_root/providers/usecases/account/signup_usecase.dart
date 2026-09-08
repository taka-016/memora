import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/signup_usecase.dart';

final signupUseCaseProvider = Provider<SignupUseCase>((ref) {
  return SignupUseCase(authService: ref.watch(authServiceProvider));
});
