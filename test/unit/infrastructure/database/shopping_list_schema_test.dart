import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/infrastructure/database/offline_database.dart';

void main() {
  test('買い物リストに未チェックの品物を保存できる', () async {
    final database = OfflineDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.insertRow('shopping_list_items', {
      'id': 'item',
      'group_id': 'group',
      'name': '牛乳',
      'quantity': '2本',
      'version': 1,
    });
    final rows = await database.rows('shopping_list_items');
    expect(rows.single['purchased_at'], isNull);
    expect(rows.single['quantity'], '2本');
  });
}
