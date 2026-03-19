import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/account/user_dto.dart';
import 'package:memora/application/mappers/account/user_mapper.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';

final watchAuthStateChangesUseCaseProvider =
    Provider<WatchAuthStateChangesUseCase>((ref) {
      return WatchAuthStateChangesUseCase(
        authService: ref.watch(authServiceProvider),
      );
    });

class WatchAuthStateChangesUseCase {
  const WatchAuthStateChangesUseCase({required this.authService});

  final AuthService authService;

  Stream<UserDto?> execute() {
    return authService.authStateChanges.map(
      (user) => user == null ? null : UserMapper.toDto(user),
    );
  }
}
