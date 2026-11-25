import 'package:memora/domain/exceptions/validation_exception.dart';

class ShoppingListItem {
  ShoppingListItem({
    required this.id,
    required this.groupId,
    required String name,
    String quantity = '',
    this.purchasedAt,
    this.version = 1,
  }) : name = name.trim(),
       quantity = quantity.trim() {
    if (this.name.isEmpty) {
      throw ValidationException('品物名を入力してください');
    }
    if (id.isEmpty || groupId.isEmpty || version < 1) {
      throw ValidationException('買い物リストの品物が不正です');
    }
  }

  final String id;
  final String groupId;
  final String name;
  final String quantity;
  final DateTime? purchasedAt;
  final int version;

  ShoppingListItem edit(String name, String quantity) {
    _requireUnchecked();
    return _change(name, quantity);
  }

  ShoppingListItem check(DateTime now) {
    _requireUnchecked();
    return _change(name, quantity, now);
  }

  ShoppingListItem undoCheck() {
    if (purchasedAt == null) {
      throw ValidationException('購入履歴の品物を指定してください');
    }
    return _change(name, quantity);
  }

  void _requireUnchecked() {
    if (purchasedAt != null) {
      throw ValidationException('未チェックの品物を指定してください');
    }
  }

  ShoppingListItem _change(
    String name,
    String quantity, [
    DateTime? purchasedAt,
  ]) => ShoppingListItem(
    id: id,
    groupId: groupId,
    name: name,
    quantity: quantity,
    purchasedAt: purchasedAt,
    version: version + 1,
  );
}
