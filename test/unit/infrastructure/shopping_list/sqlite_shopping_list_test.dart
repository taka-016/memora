import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/shopping_list_item.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/shopping_list/sqlite_shopping_list_store.dart';

void main() {
  test('購入を記録すると未チェック一覧から外れ、取り消すと元に戻る', () async {
    final database = OfflineDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = SqliteShoppingListStore(database);
    final item = ShoppingListItem(id: 'item', groupId: 'group', name: '牛乳');
    await store.add(item);
    expect((await store.watchUnchecked('group').first).single.name, '牛乳');
    final checked = item.check(DateTime.utc(2026, 11, 25));
    await store.update(checked);
    expect(await store.watchUnchecked('group').first, isEmpty);
    expect((await store.getHistory('group')).items.single.id, item.id);
    await expectLater(store.delete(item), throwsException);
    await store.update(checked.undoCheck());
    expect((await store.watchUnchecked('group').first).single.id, item.id);
    expect((await store.getHistory('group')).items, isEmpty);
  });

  test('購入履歴に品物名ごとの最新分を30件ずつ表示し、削除は対象の購入だけに適用する', () async {
    final database = OfflineDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = SqliteShoppingListStore(database);
    final firstPurchase = DateTime.utc(2026, 11, 1);
    for (var index = 0; index < 32; index++) {
      final item = ShoppingListItem(
        id: 'item-$index',
        groupId: 'group',
        name: '品物$index',
      );
      await store.add(item);
      await store.update(item.check(firstPurchase.add(Duration(days: index))));
    }
    final duplicate = ShoppingListItem(
      id: 'latest',
      groupId: 'group',
      name: '品物0',
    );
    await store.add(duplicate);
    final latest = duplicate.check(firstPurchase.add(const Duration(days: 32)));
    await store.update(latest);
    final anotherGroup = ShoppingListItem(
      id: 'another',
      groupId: 'other',
      name: '別グループの品物',
    );
    await store.add(anotherGroup);
    await store.update(anotherGroup.check(firstPurchase));

    final firstPage = await store.getHistory('group');
    expect(firstPage.items.first.id, 'latest');
    expect(firstPage.items.length, 30);
    final nextPage = await store.getHistory('group', after: firstPage.next);
    expect(nextPage.items.map((item) => item.name), ['品物2', '品物1']);
    expect(nextPage.next, isNull);

    await store.delete(latest);
    final restoredHistory = await store.getHistory('group');
    expect(restoredHistory.items.first.id, 'item-31');
    final lastPage = await store.getHistory(
      'group',
      after: restoredHistory.next,
    );
    expect(lastPage.items.map((item) => item.id), ['item-1', 'item-0']);
  });
}
