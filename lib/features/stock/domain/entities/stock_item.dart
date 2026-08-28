class StockItemEntity {
  final String productId;
  final String productName;
  final double quantity;
  final double minimumQuantity;
  final String unit;

  const StockItemEntity({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.minimumQuantity,
    required this.unit,
  });

  bool get isLowStock => quantity <= minimumQuantity;
}
