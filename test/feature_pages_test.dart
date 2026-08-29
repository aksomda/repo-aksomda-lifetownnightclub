import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/domain/usecases/get_dashboard.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/domain/entities/menu_item.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/domain/repositories/menu_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/domain/usecases/get_menu.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/presentation/controllers/menu_controller.dart'
    as menu_feature;
import 'package:repo_aksomda_lifetownnightclub/features/menu/presentation/pages/menu_page.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/entities/order.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/repositories/order_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/usecases/get_orders.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/presentation/controllers/orders_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/presentation/pages/orders_page.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/domain/entities/waitress.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/domain/repositories/staff_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/domain/usecases/get_waitresses.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/presentation/controllers/staff_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/presentation/pages/staff_page.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/domain/entities/stock_item.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/domain/repositories/stock_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/domain/usecases/get_stocks.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/presentation/controllers/stock_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/presentation/pages/stock_page.dart';

class FakeMenuRepository implements MenuRepository {
  @override
  Future<List<MenuItemEntity>> getMenu({bool forceRefresh = false}) async =>
      const [
        MenuItemEntity(
          id: '1',
          name: 'Sobbra',
          category: 'bière',
          price: 700,
          available: true,
        ),
      ];
}

class FakeOrderRepository implements OrderRepository {
  @override
  Future<List<OrderEntity>> getOrders() async => [
        OrderEntity(
          id: '1',
          tableId: '2',
          waitressId: '3',
          status: 'en_cours',
          createdAt: DateTime(2026),
          items: const [],
        ),
      ];

  @override
  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) =>
      throw UnimplementedError();

  @override
  Future<OrderEntity> updateOrderStatus({
    required String orderId,
    required String status,
  }) =>
      throw UnimplementedError();
}

class FakeStockRepository implements StockRepository {
  @override
  Future<List<StockItemEntity>> getStocks() async => const [
        StockItemEntity(
          productId: '1',
          productName: 'Coca',
          quantity: 4,
          minimumQuantity: 10,
          unit: 'bouteille',
        ),
      ];

  @override
  Future<StockItemEntity> updateQuantity({
    required String productId,
    required double quantity,
  }) =>
      throw UnimplementedError();
}

class FakeStaffRepository implements StaffRepository {
  @override
  Future<List<WaitressEntity>> getWaitresses() async =>
      const [WaitressEntity(id: '1', name: 'Awa', phone: '70000000', active: true)];

  @override
  Future<WaitressEntity> createWaitress({
    required String name,
    String? phone,
  }) =>
      throw UnimplementedError();

  @override
  Future<WaitressEntity> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) =>
      throw UnimplementedError();
}

class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async => const DashboardSummary(
        products: 10,
        orders: 20,
        lowStocks: 2,
        staff: 4,
        revenue: 50000,
      );
}

Widget host(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('MenuPage affiche les données chargées', (tester) async {
    final controller = menu_feature.MenuController(
      getMenu: GetMenu(FakeMenuRepository()),
    );

    await tester.pumpWidget(host(MenuPage(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Sobbra'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });

  testWidgets('OrdersPage affiche les commandes chargées', (tester) async {
    final controller = OrdersController(GetOrders(FakeOrderRepository()));

    await tester.pumpWidget(host(OrdersPage(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Commande #1'), findsOneWidget);
    expect(find.textContaining('en_cours'), findsOneWidget);
  });

  testWidgets('StockPage signale un stock faible', (tester) async {
    final controller = StockController(GetStocks(FakeStockRepository()));

    await tester.pumpWidget(host(StockPage(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Coca'), findsOneWidget);
    expect(find.text('Stock faible'), findsOneWidget);
  });

  testWidgets('StaffPage affiche le personnel', (tester) async {
    final controller = StaffController(GetWaitresses(FakeStaffRepository()));

    await tester.pumpWidget(host(StaffPage(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Awa'), findsOneWidget);
    expect(find.text('70000000'), findsOneWidget);
  });

  testWidgets('DashboardPage affiche les indicateurs', (tester) async {
    final controller = DashboardController(
      GetDashboard(FakeDashboardRepository()),
    );

    await tester.pumpWidget(
      host(
        DashboardPage(
          controller: controller,
          onLogout: () {},
          onNavigate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Produits'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Chiffre d’affaires'), findsOneWidget);
  });
}
