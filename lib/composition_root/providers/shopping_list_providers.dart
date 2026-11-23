import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list.dart';
import 'package:memora/composition_root/providers/app_availability_providers.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/composition_root/providers/offline_database_provider.dart';
import 'package:memora/infrastructure/config/resolved_app_mode_provider.dart';
import 'package:memora/infrastructure/services/shopping_list/firestore_shopping_list_store.dart';
import 'package:memora/infrastructure/services/shopping_list/sqlite_shopping_list_store.dart';

final shoppingListProvider = Provider<ShoppingList>((ref) {
  final store = switch (ref.watch(appModeProvider)) {
    AppMode.online => FirestoreShoppingListStore(FirebaseFirestore.instance),
    AppMode.offline => SqliteShoppingListStore(
      ref.watch(offlineDatabaseProvider),
    ),
  };
  return ShoppingList(
    store,
    ref.watch(appClockProvider),
    ref.watch(ensureAppAvailableForMutationProvider),
  );
});
