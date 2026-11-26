import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list_usecases.dart';
import 'package:memora/composition_root/providers/app_providers.dart';
import 'package:memora/domain/repositories/shopping_list_repository.dart';
import 'package:memora/composition_root/factories/query_service_factory.dart';
import 'package:memora/composition_root/factories/repository_factory.dart';

final _shoppingListRepositoryProvider = Provider(
  (ref) => RepositoryFactory.create<ShoppingListRepository>(ref: ref),
);

final _shoppingListQueryServiceProvider = Provider(
  (ref) => QueryServiceFactory.create<ShoppingListQueryService>(ref: ref),
);

final watchUncheckedShoppingItemsUseCaseProvider = Provider(
  (ref) => WatchUncheckedShoppingItemsUseCase(
    ref.watch(_shoppingListQueryServiceProvider),
  ),
);
final getShoppingHistoryUseCaseProvider = Provider(
  (ref) =>
      GetShoppingHistoryUseCase(ref.watch(_shoppingListQueryServiceProvider)),
);
final addShoppingItemUseCaseProvider = Provider(
  (ref) => AddShoppingItemUseCase(ref.watch(_shoppingListRepositoryProvider)),
);
final editShoppingItemUseCaseProvider = Provider(
  (ref) => EditShoppingItemUseCase(ref.watch(_shoppingListRepositoryProvider)),
);
final deleteShoppingItemUseCaseProvider = Provider(
  (ref) =>
      DeleteShoppingItemUseCase(ref.watch(_shoppingListRepositoryProvider)),
);
final checkShoppingItemUseCaseProvider = Provider(
  (ref) => CheckShoppingItemUseCase(
    ref.watch(_shoppingListRepositoryProvider),
    ref.watch(appClockProvider),
  ),
);
final undoShoppingItemCheckUseCaseProvider = Provider(
  (ref) =>
      UndoShoppingItemCheckUseCase(ref.watch(_shoppingListRepositoryProvider)),
);
final deleteShoppingHistoryUseCaseProvider = Provider(
  (ref) =>
      DeleteShoppingHistoryUseCase(ref.watch(_shoppingListRepositoryProvider)),
);
