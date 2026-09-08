import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/models/app_capabilities.dart';
import 'package:memora/application/exceptions/feature_unavailable_exception.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/services/auth_service.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthServiceFactory.create(ref: ref);
});

class AuthServiceFactory {
  static AuthService create({required Ref ref}) {
    final authType = ref.watch(appModeProvider);
    return _createServiceByType(ref: ref, authType: authType);
  }

  static AuthService _createServiceByType({
    required Ref ref,
    required AppMode authType,
  }) {
    switch (authType) {
      case AppMode.online:
        return FirebaseAuthService(
          firebaseAuth: ref.watch(firebaseAuthProvider),
        );
      case AppMode.offline:
        throw const FeatureUnavailableException(
          AppFeature.authentication,
          'この機能はオンラインモードで利用できます。',
        );
    }
  }
}
