import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/interfaces/group_query_service.dart';
import 'package:memora/application/interfaces/pin_query_service.dart';
import 'package:memora/infrastructure/config/database_type.dart';
import 'package:memora/infrastructure/config/database_type_provider.dart';
import 'package:memora/infrastructure/services/firestore_group_query_service.dart';
import 'package:memora/infrastructure/services/firestore_pin_query_service.dart';

class QueryServiceFactory {
  static T create<T extends Object>({required Ref ref}) {
    final dbType = ref.read(databaseTypeProvider);
    return _createQueryServiceByType<T>(dbType);
  }

  static T createWithWidgetRef<T extends Object>({required WidgetRef ref}) {
    final dbType = ref.read(databaseTypeProvider);
    return _createQueryServiceByType<T>(dbType);
  }

  static T _createQueryServiceByType<T extends Object>(DatabaseType dbType) {
    switch (dbType) {
      case DatabaseType.firestore:
        return _createFirestoreQueryService<T>();
      case DatabaseType.sqlite:
        throw UnimplementedError(
          'Supabase implementation is not yet available',
        );
    }
  }

  static T _createFirestoreQueryService<T>() {
    if (T == GroupQueryService) {
      return FirestoreGroupQueryService() as T;
    }
    if (T == PinQueryService) {
      return FirestorePinQueryService() as T;
    }
    throw ArgumentError('Unknown query service type: $T');
  }
}
