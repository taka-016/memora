import 'dart:async';

import 'package:material_ui/material_ui.dart';
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
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _openShoppingList(tester, store);

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

  testWidgets('別の品物が先頭に追加されても行内編集を保存できる', (tester) async {
    final store = _ShoppingListStore()..item = _milk();
    await _openShoppingList(tester, store);
    await tester.enterText(find.byType(TextField).last, '2本');
    await tester.pump();
    store.extra = ShoppingListItem(id: 'apple', groupId: 'group', name: 'りんご');
    store.changes.add(store.unchecked);
    await tester.pumpAndSettle();
    await tester.tap(find.text('家族'));
    await tester.pumpAndSettle();
    expect(store.item?.quantity, '2本');
  });

  testWidgets('購入の保存中は履歴を開けず完了後に購入した品物が表示される', (tester) async {
    final store = _ShoppingListStore()
      ..item = _milk()
      ..pendingUpdate = Completer<void>();
    await _openShoppingList(tester, store);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    final history = find.widgetWithText(TextButton, '購入履歴');
    expect(tester.widget<TextButton>(history).enabled, isFalse);
    store.pendingUpdate!.complete();
    await tester.pumpAndSettle();
    await tester.tap(history);
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
    expect(find.text('再登録'), findsOneWidget);
  });

  testWidgets('別端末との競合後は取得し直した購入履歴から削除できる', (tester) async {
    final store = _ShoppingListStore()
      ..item = _milk().check(DateTime.utc(2026, 11, 24));
    await _openShoppingList(tester, store);
    await tester.tap(find.widgetWithText(TextButton, '購入履歴'));
    await tester.pumpAndSettle();
    store.item = store.item!.register('').check(DateTime.utc(2026, 11, 25));
    await tester.tap(find.byTooltip('購入履歴を削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('購入履歴を削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();
    expect(find.text('購入履歴はありません'), findsOneWidget);
  });

  testWidgets('別端末で削除された購入履歴から同名の品物を作り直さない', (tester) async {
    final store = _ShoppingListStore()
      ..item = _milk().check(DateTime.utc(2026, 11, 25));
    await _openShoppingList(tester, store);
    await tester.tap(find.widgetWithText(TextButton, '購入履歴'));
    await tester.pumpAndSettle();
    store.item = null;
    await tester.tap(find.text('再登録'));
    await tester.pumpAndSettle();
    expect(store.item, isNull);
    expect(find.widgetWithText(TextButton, '閉じる'), findsOneWidget);
  });

  testWidgets('ページをまたいで購入日時が変わった品物は履歴に1件だけ表示する', (tester) async {
    final recent = ShoppingListItemMapper.toDto(
      _milk().check(DateTime.utc(2026, 11, 25)),
    );
    final older = ShoppingListItemMapper.toDto(
      _milk().check(DateTime.utc(2026, 11, 24)),
    );
    final store = _ShoppingListStore()
      ..historyPage = (after) => after == null
          ? (items: [recent], next: ShoppingHistoryCursor(recent))
          : (items: [older], next: null);
    await _openShoppingList(tester, store);
    await tester.tap(find.widgetWithText(TextButton, '購入履歴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('さらに表示'));
    await tester.pumpAndSettle();
    expect(find.text('牛乳'), findsOneWidget);
  });
}

ShoppingListItem _milk() =>
    ShoppingListItem(id: 'milk', groupId: 'group', name: '牛乳');

Future<void> _openShoppingList(
  WidgetTester tester,
  _ShoppingListStore store,
) async {
  final clock = FixedAppClock(DateTime.utc(2026, 11, 25));
  addTearDown(store.changes.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getShoppingHistoryUseCaseProvider.overrideWithValue(
          GetShoppingHistoryUseCase(store),
        ),
        deleteShoppingHistoryUseCaseProvider.overrideWithValue(
          DeleteShoppingHistoryUseCase(store),
        ),
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
}

class _ShoppingListStore
    implements ShoppingListQueryService, ShoppingListRepository {
  final changes = StreamController<List<ShoppingListItemDto>>.broadcast();
  ShoppingListItem? item;
  ShoppingListItem? extra;
  Completer<void>? pendingUpdate;
  ShoppingHistoryPage Function(ShoppingHistoryCursor?)? historyPage;
  bool failNextUpdate = false;

  List<ShoppingListItemDto> get unchecked {
    final current = item;
    final other = extra;
    return [
      if (other != null) ShoppingListItemMapper.toDto(other),
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
  }) async {
    final readPage = historyPage;
    if (readPage != null) return readPage(after);
    final current = item;
    return (
      items: [
        if (current != null && current.purchasedAt != null)
          ShoppingListItemMapper.toDto(current),
      ],
      next: null,
    );
  }

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
    await pendingUpdate?.future;
    if (this.item?.version != expected.version) {
      throw TestException('品物が変更されています');
    }
    await add(item);
  }

  @override
  Future<void> delete(ShoppingListItem expected) async {
    if (item?.version != expected.version) {
      throw TestException('購入履歴が変更されています');
    }
    item = null;
    changes.add(unchecked);
  }
}
