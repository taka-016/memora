import 'package:memora/application/dtos/copy_with_helper.dart';

class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.name,
    this.version = 0,
    this.pendingQuantity,
    this.lastAddedAt,
    this.purchasedAt,
    this.purchasedQuantity,
  });

  final String id;
  final String name;
  final int version;
  final String? pendingQuantity;
  final DateTime? lastAddedAt;
  final DateTime? purchasedAt;
  final String? purchasedQuantity;

  ShoppingListItem copyWith({
    String? id,
    int? version,
    Object? pendingQuantity = copyWithPlaceholder,
    Object? lastAddedAt = copyWithPlaceholder,
    Object? purchasedAt = copyWithPlaceholder,
    Object? purchasedQuantity = copyWithPlaceholder,
  }) => ShoppingListItem(
    id: id ?? this.id,
    name: name,
    version: version ?? this.version,
    pendingQuantity: resolveCopyWithValue(
      pendingQuantity,
      this.pendingQuantity,
      'pendingQuantity',
    ),
    lastAddedAt: resolveCopyWithValue(
      lastAddedAt,
      this.lastAddedAt,
      'lastAddedAt',
    ),
    purchasedAt: resolveCopyWithValue(
      purchasedAt,
      this.purchasedAt,
      'purchasedAt',
    ),
    purchasedQuantity: resolveCopyWithValue(
      purchasedQuantity,
      this.purchasedQuantity,
      'purchasedQuantity',
    ),
  );
}
