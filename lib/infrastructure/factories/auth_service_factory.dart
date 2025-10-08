import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/infrastructure/config/auth_type.dart';
import 'package:memora/infrastructure/config/auth_type_provider.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceFactory.create<AuthService>(ref: ref);
});

class AuthServiceFactory {
  static T create<T extends Object>({required Ref ref}) {
    final authType = ref.read(authTypeProvider);
    return _createServiceByType<T>(authType);
  }

  static T _createServiceByType<T extends Object>(AuthType authType) {
    switch (authType) {
      case AuthType.firebase:
        return _createFirebaseAuthService<T>();
      case AuthType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }

  static T _createFirebaseAuthService<T>() {
    if (T == AuthService) {
      return FirebaseAuthService() as T;
    }
    throw ArgumentError('Unknown service type: $T');
  }
}
