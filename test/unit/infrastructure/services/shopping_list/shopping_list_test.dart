import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/application/usecases/shopping_list/shopping_list.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/infrastructure/database/offline_database.dart';
import 'package:memora/infrastructure/services/shopping_list/sqlite_shopping_list_store.dart';

class _Clock implements AppClock {
  var time = DateTime.utc(2026, 11, 24);

  @override
  DateTime now() => time;

  @override
  Future<void> sync() async {}
}

void main() {
  late OfflineDatabase database;
  late ShoppingList list;
  late _Clock clock;
  setUp(() {
    database = OfflineDatabase(NativeDatabase.memory());
    clock = _Clock();
    list = ShoppingList(SqliteShoppingListStore(database), clock, () async {});
  });
  tearDown(() async => database.close());

  test('同じグループに品物を共有し、追加済みの品物は数量を編集できる', () async {
    await list.add('家族', '  牛乳  ', '2本');
    final other = ShoppingList(
      SqliteShoppingListStore(database),
      clock,
      () async {},
    );
    final item = (await other.watchPending('家族').first).single;
    expect(item.name, '牛乳');
    expect(item.pendingQuantity, '2本');
    expect(await other.watchPending('別グループ').first, isEmpty);

    final duplicate = await other.add('家族', '牛乳', '1本');
    expect(duplicate?.pendingQuantity, '2本');
    await other.edit('家族', duplicate!, '牛乳', '1本');
    expect((await list.watchPending('家族').first).single.pendingQuantity, '1本');
    expect((await list.additions('家族')).map((item) => item.name), ['牛乳']);
  });

  test('チェックを元に戻すと前回の購入済み履歴と今回の数量に戻る', () async {
    await list.add('家族', '牛乳', '1本');
    await list.check('家族', (await list.watchPending('家族').first).single);
    final firstPurchase = (await list.purchases('家族')).single;
    clock.time = DateTime.utc(2026, 11, 25);
    await list.add('家族', '牛乳', '2本');
    final addedAt = (await list.additions('家族')).single.lastAddedAt;
    final pending = (await list.watchPending('家族').first).single;

    clock.time = DateTime.utc(2026, 11, 26);
    final checked = await list.check('家族', pending);
    expect(await list.watchPending('家族').first, isEmpty);
    expect((await list.purchases('家族')).single.purchasedQuantity, '2本');
    expect((await list.additions('家族')).single.lastAddedAt, addedAt);

    await list.undo('家族', pending, checked);
    expect((await list.watchPending('家族').first).single.pendingQuantity, '2本');
    final restored = (await list.purchases('家族')).single;
    expect(restored.purchasedQuantity, '1本');
    expect(restored.purchasedAt, firstPurchase.purchasedAt);
  });

  test('未チェックの品物を物理削除して履歴を保ち、再追加しても以前の品物とは区別する', () async {
    await list.add('家族', '牛乳', '1本');
    await list.check('家族', (await list.watchPending('家族').first).single);
    final purchased = (await list.purchases('家族')).single;
    clock.time = DateTime.utc(2026, 11, 25);
    await list.add('家族', '牛乳', '2本');
    final pending = (await list.watchPending('家族').first).single;
    await list.delete('家族', pending);

    expect(await list.watchPending('家族').first, isEmpty);
    expect(
      await database.rows(
        'shopping_list_items',
        where: 'id = ?',
        args: [pending.id],
      ),
      isEmpty,
    );
    expect(
      (await list.additions('家族')).single.lastAddedAt,
      pending.lastAddedAt,
    );
    expect(
      (await list.purchases('家族')).single.purchasedAt,
      purchased.purchasedAt,
    );
    expect((await list.purchases('家族')).single.purchasedQuantity, '1本');

    clock.time = DateTime.utc(2026, 11, 26);
    await list.add('家族', '牛乳', '3本');
    final added = (await list.watchPending('家族').first).single;
    expect(added.pendingQuantity, '3本');
    expect((await list.additions('家族')).single.lastAddedAt, clock.time);
    expect((await list.purchases('家族')).single.purchasedQuantity, '1本');
    expect(added.version, greaterThan(pending.version));
  });

  test('追加履歴と購入済み履歴は個別に削除でき、未チェックの品物は残る', () async {
    await list.add('家族', '牛乳', '1本');
    await list.check('家族', (await list.watchPending('家族').first).single);
    await list.add('家族', '牛乳', '2本');

    await list.deleteAddition('家族', (await list.additions('家族')).single);
    expect(await list.additions('家族'), isEmpty);
    expect((await list.purchases('家族')).single.purchasedQuantity, '1本');
    expect((await list.watchPending('家族').first).single.pendingQuantity, '2本');

    final current = (await list.watchPending('家族').first).single;
    await list.check('家族', current);
    await list.add('家族', '牛乳', '3本');
    final addedAt = (await list.additions('家族')).single.lastAddedAt;
    await list.deletePurchase('家族', (await list.purchases('家族')).single);
    expect(await list.purchases('家族'), isEmpty);
    expect((await list.additions('家族')).single.lastAddedAt, addedAt);
    expect((await list.watchPending('家族').first).single.pendingQuantity, '3本');
  });

  test('購入済み履歴を新しい順に最大30件ずつ取得する', () async {
    for (var i = 0; i < 33; i++) {
      clock.time = DateTime.utc(2026, 11, 24, 0, i == 32 ? 31 : i);
      await list.add('家族', '品物$i', '');
      await list.check('家族', (await list.watchPending('家族').first).single);
    }
    final first = await list.purchases('家族');
    final second = await list.purchases('家族', after: first.last);
    expect(first, hasLength(30));
    expect(
      first.take(2).map((item) => item.name),
      unorderedEquals(['品物31', '品物32']),
    );
    expect(second.map((item) => item.name), ['品物2', '品物1', '品物0']);
    expect(await list.purchases('家族', after: second.last), isEmpty);
  });
}
