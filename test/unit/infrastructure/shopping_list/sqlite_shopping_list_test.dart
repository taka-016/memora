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
}
