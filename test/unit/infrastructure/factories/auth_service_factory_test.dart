import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/config/auth_type.dart';
import 'package:memora/infrastructure/config/auth_type_provider.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

import '../services/firebase_auth_service_test.mocks.dart';

void main() {
  group('AuthServiceFactory', () {
    test('firebase指定時はFirebaseAuthServiceを返す', () {
      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
      );
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);

      expect(service, isA<FirebaseAuthService>());
    });

    test('local指定時は未実装エラーを投げる', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authTypeProvider.notifier).state = AuthType.local;

      expect(
        () => container.read(authServiceProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
