class ShoppingListItemDto {
  const ShoppingListItemDto({
    required this.id,
    required this.groupId,
    required this.name,
    required this.quantity,
    required this.isListed,
    required this.purchasedAt,
    required this.version,
  });

  final String id;
  final String groupId;
  final String name;
  final String quantity;
  final bool isListed;
  final DateTime? purchasedAt;
  final int version;
}
