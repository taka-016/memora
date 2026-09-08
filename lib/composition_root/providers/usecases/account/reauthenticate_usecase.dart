import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/reauthenticate_usecase.dart';

final reauthenticateUseCaseProvider = Provider<ReauthenticateUseCase>((ref) {
  return ReauthenticateUseCase(authService: ref.watch(authServiceProvider));
});
