import 'package:flutter_riverpod/legacy.dart';
import 'package:memora/infrastructure/config/database_type.dart';

final databaseTypeProvider = StateProvider<DatabaseType>(
  (ref) => DatabaseType.firestore,
);
