import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/dtos/shopping_list_item_dto.dart';
import 'package:memora/application/mappers/shopping_list_item_mapper.dart';
import 'package:memora/application/queries/shopping_list_query_service.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list_usecases.dart';
import 'package:memora/composition_root/providers/shopping_list_providers.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';
import 'package:memora/domain/repositories/shopping_list_repository.dart';
import 'package:memora/infrastructure/time/fixed_app_clock.dart';
import 'package:memora/presentation/features/shopping_list/shopping_list_page.dart';

import '../../../../helpers/test_exception.dart';

void main() {
  testWidgets('数量の行内編集を保存し、購入の失敗後に再試行して取り消せる', (tester) async {
    final store = _ShoppingListStore();
    final clock = FixedAppClock(DateTime.utc(2026, 11, 25));
    addTearDown(store.changes.close);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchUncheckedShoppingItemsUseCaseProvider.overrideWithValue(
            WatchUncheckedShoppingItemsUseCase(store),
          ),
          addShoppingItemUseCaseProvider.overrideWithValue(
            AddShoppingItemUseCase(store),
          ),
          editShoppingItemUseCaseProvider.overrideWithValue(
            EditShoppingItemUseCase(store),
          ),
          checkShoppingItemUseCaseProvider.overrideWithValue(
            CheckShoppingItemUseCase(store, clock),
          ),
          undoShoppingItemCheckUseCaseProvider.overrideWithValue(
            UndoShoppingItemCheckUseCase(store),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ShoppingListPage(
              groupId: 'group',
              groupName: '家族',
              onBack: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '牛乳');
    await tester.pump();
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '2本');
    await tester.pump();
    await tester.tap(find.text('家族'));
    await tester.pumpAndSettle();
    expect(store.item?.quantity, '2本');

    store.failNextUpdate = true;
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('元に戻す'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('2本'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ShoppingListStore
    implements ShoppingListQueryService, ShoppingListRepository {
  final changes = StreamController<List<ShoppingListItemDto>>.broadcast();
  ShoppingListItem? item;
  bool failNextUpdate = false;

  List<ShoppingListItemDto> get unchecked {
    final current = item;
    return [
      if (current != null && current.isListed)
        ShoppingListItemMapper.toDto(current),
    ];
  }

  @override
  Stream<List<ShoppingListItemDto>> watchUnchecked(String groupId) async* {
    yield unchecked;
    yield* changes.stream;
  }

  @override
  Future<ShoppingHistoryPage> getHistory(
    String groupId, {
    ShoppingHistoryCursor? after,
  }) => throw UnimplementedError();

  @override
  Future<void> add(ShoppingListItem item) async {
    this.item = item;
    changes.add(unchecked);
  }

  @override
  Future<void> update(ShoppingListItem expected, ShoppingListItem item) async {
    if (failNextUpdate) {
      failNextUpdate = false;
      throw TestException('買い物リストの保存に失敗しました');
    }
    await add(item);
  }

  @override
  Future<void> delete(ShoppingListItem expected) => throw UnimplementedError();
}
