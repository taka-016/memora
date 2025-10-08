import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/auth_service.dart';
import 'package:memora/infrastructure/config/database_type.dart';
import 'package:memora/infrastructure/config/database_type_provider.dart';
import 'package:memora/infrastructure/services/firebase_auth_service.dart';

class AuthServiceFactory {
  static T create<T extends Object>({required Ref ref}) {
    final dbType = ref.read(databaseTypeProvider);
    return _createServiceByType<T>(dbType);
  }

  static T createWithWidgetRef<T extends Object>({required WidgetRef ref}) {
    final dbType = ref.read(databaseTypeProvider);
    return _createServiceByType<T>(dbType);
  }

  static T _createServiceByType<T extends Object>(DatabaseType dbType) {
    switch (dbType) {
      case DatabaseType.firestore:
        return _createFirebaseAuthService<T>();
      case DatabaseType.sqlite:
        throw UnimplementedError(
          'Supabase implementation is not yet available',
        );
    }
  }

  static T _createFirebaseAuthService<T>() {
    if (T == AuthService) {
      return FirebaseAuthService() as T;
    }
    throw ArgumentError('Unknown service type: $T');
  }
}
