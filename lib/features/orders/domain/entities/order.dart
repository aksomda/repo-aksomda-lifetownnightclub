class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

class OrderEntity {
  final String id;
  final String? tableId;
  final String? waitressId;
  final List<OrderItem> items;
  final String status;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    this.tableId,
    this.waitressId,
    required this.items,
    required this.status,
    required this.createdAt,
  });

  double get total {
    return items.fold(0, (sum, item) => sum + item.total);
  }
}
