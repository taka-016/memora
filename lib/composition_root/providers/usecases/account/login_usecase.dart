import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/login_usecase.dart';

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(authService: ref.watch(authServiceProvider));
});
