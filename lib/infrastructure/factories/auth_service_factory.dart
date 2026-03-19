import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/config/auth_type.dart';
import 'package:memora/infrastructure/config/auth_type_provider.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceFactory.create(ref: ref);
});

class AuthServiceFactory {
  static AuthService create({required Ref ref}) {
    final authType = ref.watch(authTypeProvider);
    return _createServiceByType(ref: ref, authType: authType);
  }

  static AuthService _createServiceByType({
    required Ref ref,
    required AuthType authType,
  }) {
    switch (authType) {
      case AuthType.firebase:
        return FirebaseAuthService(
          firebaseAuth: ref.watch(firebaseAuthProvider),
        );
      case AuthType.local:
        throw UnimplementedError('Local implementation is not yet available');
    }
  }
}
