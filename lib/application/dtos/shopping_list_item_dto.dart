class ShoppingListItemDto {
  const ShoppingListItemDto({
    required this.id,
    required this.groupId,
    required this.name,
    required this.quantity,
    required this.purchasedAt,
    required this.version,
  });

  final String id;
  final String groupId;
  final String name;
  final String quantity;
  final DateTime? purchasedAt;
  final int version;
}
