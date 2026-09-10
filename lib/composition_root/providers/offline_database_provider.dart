import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  final database = OfflineDatabase.device();
  ref.onDispose(() { unawaited(database.close()); });
  return database;
});
