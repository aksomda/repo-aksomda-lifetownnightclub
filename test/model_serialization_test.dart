import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/data/models/order_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/entities/order.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/data/models/waitress_model.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/data/models/stock_item_model.dart';

void main() {
  test('StockItemModel round-trip JSON', () {
    const model = StockItemModel(
      productId: '1',
      productName: 'Coca',
      quantity: 12,
      minimumQuantity: 5,
      unit: 'bouteille',
    );

    expect(StockItemModel.fromJson(model.toJson()).productName, 'Coca');
    expect(StockItemModel.fromJson(model.toJson()).quantity, 12);
  });

  test('WaitressModel round-trip JSON', () {
    const model = WaitressModel(
      id: '1',
      name: 'Awa',
      phone: '70000000',
      active: false,
    );

    final restored = WaitressModel.fromJson(model.toJson());

    expect(restored.name, 'Awa');
    expect(restored.active, isFalse);
  });

  test('DashboardSummaryModel round-trip JSON', () {
    const model = DashboardSummaryModel(
      products: 10,
      orders: 20,
      lowStocks: 2,
      staff: 4,
      revenue: 50000,
    );

    final restored = DashboardSummaryModel.fromJson(model.toJson());

    expect(restored.orders, 20);
    expect(restored.revenue, 50000);
  });

  test('OrderModel round-trip JSON conserve les articles', () {
    final model = OrderModel(
      id: '1',
      tableId: '2',
      waitressId: '3',
      status: 'payee',
      createdAt: DateTime(2026, 8, 1),
      items: const [
        OrderItem(
          productId: '10',
          productName: 'Sobbra',
          quantity: 2,
          unitPrice: 700,
        ),
      ],
    );

    final restored = OrderModel.fromJson(model.toJson());

    expect(restored.id, '1');
    expect(restored.items.single.productName, 'Sobbra');
    expect(restored.total, 1400);
  });
}
