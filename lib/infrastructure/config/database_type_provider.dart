import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/config/database_type.dart';

final databaseTypeProvider = StateProvider<DatabaseType>(
  (ref) => DatabaseType.firestore,
);
