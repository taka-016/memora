import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/application/usecases/account/observe_auth_state_changes_usecase.dart';

final observeAuthStateChangesUseCaseProvider =
    Provider<ObserveAuthStateChangesUseCase>((ref) {
      return ObserveAuthStateChangesUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });
