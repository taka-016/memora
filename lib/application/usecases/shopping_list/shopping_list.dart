import 'dart:convert';

import 'package:memora/application/dtos/shopping_list/shopping_list_item.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/services/shopping_list/shopping_list_store.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:uuid/uuid.dart';

class ShoppingList {
  const ShoppingList(this._store, this._clock, this._ensureAvailable);

  // ignore: constant_identifier_names
  static const PURCHASE_PAGE_SIZE = 30;

  final ShoppingListStore _store;
  final AppClock _clock;
  final Future<void> Function() _ensureAvailable;

  Stream<List<ShoppingListItem>> watchPending(String groupId) => _store
      .watchPending(groupId)
      .map((items) => [...items]..sort((a, b) => a.name.compareTo(b.name)));

  Future<List<ShoppingListItem>> additions(String groupId) =>
      _store.additions(groupId);

  Future<List<ShoppingListItem>> purchases(
    String groupId, {
    ShoppingListItem? after,
  }) => _store.purchases(groupId, limit: PURCHASE_PAGE_SIZE, after: after);

  Future<ShoppingListItem?> add(
    String groupId,
    String name,
    String quantity,
  ) async {
    final item = _newItem(groupId, name);
    await _ensureAvailable();
    final addedAt = _clock.now();
    return _store.write(groupId, (scope) async {
      final current = await scope.read(item.id) ?? item;
      if (current.pendingQuantity != null) return current;
      await scope.save(
        current.copyWith(
          version: current.version + 1,
          pendingQuantity: quantity.trim(),
          lastAddedAt: addedAt,
        ),
      );
      return null;
    });
  }

  Future<ShoppingListItem?> edit(
    String groupId,
    ShoppingListItem original,
    String name,
    String quantity,
  ) async {
    final target = _newItem(groupId, name);
    await _ensureAvailable();
    return _store.write(groupId, (scope) async {
      final current = await _requireCurrent(scope, original);
      if (current.id == target.id) {
        await scope.save(
          current.copyWith(
            version: current.version + 1,
            pendingQuantity: quantity.trim(),
          ),
        );
        return null;
      }
      final destination = await scope.read(target.id) ?? target;
      if (destination.pendingQuantity != null) return destination;
      await scope.save(
        current.copyWith(version: current.version + 1, pendingQuantity: null),
      );
      await scope.save(
        destination.copyWith(
          version: destination.version + 1,
          pendingQuantity: quantity.trim(),
        ),
      );
      return null;
    });
  }

  Future<ShoppingListItem> check(
    String groupId,
    ShoppingListItem original,
  ) async {
    await _ensureAvailable();
    final purchasedAt = _clock.now();
    return _store.write(groupId, (scope) async {
      final current = await _requireCurrent(scope, original);
      final checked = current.copyWith(
        version: current.version + 1,
        pendingQuantity: null,
        purchasedAt: purchasedAt,
        purchasedQuantity: current.pendingQuantity,
      );
      await scope.save(checked);
      return checked;
    });
  }

  Future<void> undo(
    String groupId,
    ShoppingListItem original,
    ShoppingListItem checked,
  ) async {
    await _ensureAvailable();
    await _store.write(groupId, (scope) async {
      final current = await _requireCurrent(scope, checked);
      await scope.save(
        current.copyWith(
          version: current.version + 1,
          pendingQuantity: original.pendingQuantity,
          purchasedAt: original.purchasedAt,
          purchasedQuantity: original.purchasedQuantity,
        ),
      );
    });
  }

  ShoppingListItem _newItem(String groupId, String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ApplicationValidationException('品物名を入力してください。');
    }
    final id = const Uuid().v5(
      Namespace.url.value,
      jsonEncode([groupId, trimmedName]),
    );
    return ShoppingListItem(id: id, name: trimmedName);
  }

  Future<ShoppingListItem> _requireCurrent(
    ShoppingListWriteScope scope,
    ShoppingListItem expected,
  ) async {
    final current = await scope.read(expected.id);
    if (current == null || current.version != expected.version) {
      throw const ApplicationValidationException('品物が変更されました。一覧を確認してください。');
    }
    return current;
  }
}
