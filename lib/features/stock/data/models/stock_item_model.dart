import '../../domain/entities/stock_item.dart';

class StockItemModel extends StockItemEntity {
  const StockItemModel({
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.minimumQuantity,
    required super.unit,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> j) => StockItemModel(
    productId: '${j['product_id'] ?? j['id'] ?? ''}',
    productName: '${j['product_name'] ?? j['name'] ?? ''}',
    quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
    minimumQuantity: (j['minimum_quantity'] as num?)?.toDouble() ?? 0,
    unit: '${j['unit'] ?? 'unité'}',
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'quantity': quantity,
    'minimum_quantity': minimumQuantity,
    'unit': unit,
  };
}
