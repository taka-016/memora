import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/shopping_list/sqlite_shopping_list_store.dart';
import 'package:memora/application/mappers/shopping_list_item_mapper.dart';

void main() {
  late OfflineDatabase database;
  late SqliteShoppingListStore store;

  setUp(() {
    database = OfflineDatabase(NativeDatabase.memory());
    store = SqliteShoppingListStore(database);
    addTearDown(database.close);
  });

  test('同じ品物を再登録しても1件にまとまり、購入履歴だけを一度で削除できる', () async {
    final item = ShoppingListItem(
      id: 'item',
      groupId: 'group',
      name: '牛乳',
      quantity: '2本',
    );
    await store.add(item);
    final checked = item.check(DateTime.utc(2026, 11, 25));
    await store.update(item, checked);
    expect(await store.watchUnchecked('group').first, isEmpty);
    await expectLater(store.delete(item), throwsException);

    await store.add(
      ShoppingListItem(id: 'new', groupId: 'group', name: ' 牛乳 '),
    );
    final active = ShoppingListItemMapper.toEntity(
      (await store.watchUnchecked('group').first).single,
    );
    expect(active.id, item.id);
    expect(active.quantity, isEmpty);
    expect(
      (await store.getHistory('group')).items.single.purchasedAt,
      checked.purchasedAt,
    );
    expect(await database.rows('shopping_list_items'), hasLength(1));

    final boughtAgain = active.check(DateTime.utc(2026, 11, 26));
    await store.update(active, boughtAgain);
    await store.update(boughtAgain, boughtAgain.undoCheck(active.purchasedAt));
    final restored = ShoppingListItemMapper.toEntity(
      (await store.watchUnchecked('group').first).single,
    );
    expect(restored.purchasedAt, checked.purchasedAt);
    await store.update(restored, restored.clearPurchase());
    expect((await store.getHistory('group')).items, isEmpty);
    expect((await store.watchUnchecked('group').first).single.name, '牛乳');
  });

  test('購入履歴をグループ別に購入日の降順で30件ずつ取得する', () async {
    final firstPurchase = DateTime.utc(2026, 11, 1);
    for (var index = 0; index < 32; index++) {
      final item = ShoppingListItem(
        id: 'item-$index',
        groupId: 'group',
        name: '品物$index',
      );
      await store.add(item);
      await store.update(
        item,
        item.check(firstPurchase.add(Duration(days: index))),
      );
    }
    final other = ShoppingListItem(id: 'other', groupId: 'other', name: '品物0');
    await store.add(other);
    await store.update(other, other.check(firstPurchase));

    final firstPage = await store.getHistory('group');
    expect(firstPage.items.first.id, 'item-31');
    expect(firstPage.items.length, 30);
    final nextPage = await store.getHistory('group', after: firstPage.next);
    expect(nextPage.items.map((item) => item.id), ['item-1', 'item-0']);
    expect(nextPage.next, isNull);
  });

  test('同名の品物への改名と同時追加を拒否する', () async {
    final milk = ShoppingListItem(id: 'milk', groupId: 'group', name: '牛乳');
    final eggs = ShoppingListItem(id: 'eggs', groupId: 'group', name: '卵');
    await Future.wait([store.add(milk), store.add(eggs)]);
    await expectLater(
      store.add(ShoppingListItem(id: 'other', groupId: 'group', name: '牛乳')),
      throwsException,
    );
    await expectLater(store.update(eggs, eggs.edit('牛乳', '')), throwsException);
    expect(
      (await store.watchUnchecked('group').first).map((item) => item.name),
      unorderedEquals(['牛乳', '卵']),
    );
  });
}
