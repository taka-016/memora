import 'package:memora/domain/exceptions/validation_exception.dart';

class ShoppingListItem {
  ShoppingListItem({
    required this.id,
    required this.groupId,
    required String name,
    String quantity = '',
    this.isListed = true,
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
  final bool isListed;
  final DateTime? purchasedAt;
  final int version;

  ShoppingListItem edit(String name, String quantity) {
    _requireListed();
    return _change(name, quantity, true, purchasedAt);
  }

  ShoppingListItem register(String quantity) {
    if (isListed) {
      throw ValidationException('同名の品物は追加済みです');
    }
    return _change(name, quantity, true, purchasedAt);
  }

  ShoppingListItem removeFromList() {
    _requireListed();
    return _change(name, quantity, false, purchasedAt);
  }

  ShoppingListItem check(DateTime now) {
    _requireListed();
    return _change(name, quantity, false, now);
  }

  ShoppingListItem undoCheck(DateTime? previousPurchase) {
    if (isListed || purchasedAt == null) {
      throw ValidationException('購入済みの品物を指定してください');
    }
    return _change(name, quantity, true, previousPurchase);
  }

  ShoppingListItem clearPurchase() {
    if (purchasedAt == null) {
      throw ValidationException('購入履歴の品物を指定してください');
    }
    return _change(name, quantity, isListed, null);
  }

  void _requireListed() {
    if (!isListed) {
      throw ValidationException('買い物リストにある品物を指定してください');
    }
  }

  ShoppingListItem _change(
    String name,
    String quantity,
    bool isListed,
    DateTime? purchasedAt,
  ) => ShoppingListItem(
    id: id,
    groupId: groupId,
    name: name,
    quantity: quantity,
    isListed: isListed,
    purchasedAt: purchasedAt,
    version: version + 1,
  );
}
