import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/factories/auth_service_factory.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

import '../services/firebase_auth_service_test.mocks.dart';

void main() {
  group('AuthServiceFactory', () {
    test('オンラインモードではFirebaseAuthServiceを返す', () {
      final container = ProviderContainer(
        overrides: [firebaseAuthProvider.overrideWithValue(MockFirebaseAuth())],
      );
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);

      expect(service, isA<FirebaseAuthService>());
    });
  });
}
