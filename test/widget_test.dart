// Smoke test: verifies that LifetownApp builds correctly with all its
// controllers wired up, and that the login screen is shown when the user
// is not authenticated.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/login.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/logout.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/register.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/domain/usecases/get_dashboard.dart';
import 'package:repo_aksomda_lifetownnightclub/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/domain/entities/menu_item.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/domain/repositories/menu_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/domain/usecases/get_menu.dart';
import 'package:repo_aksomda_lifetownnightclub/features/menu/presentation/controllers/menu_controller.dart'
    as menu_feature;
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/entities/order.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/repositories/order_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/domain/usecases/get_orders.dart';
import 'package:repo_aksomda_lifetownnightclub/features/orders/presentation/controllers/orders_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/domain/entities/waitress.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/domain/repositories/staff_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/domain/usecases/get_waitresses.dart';
import 'package:repo_aksomda_lifetownnightclub/features/staff/presentation/controllers/staff_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/domain/entities/stock_item.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/domain/repositories/stock_repository.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/domain/usecases/get_stocks.dart';
import 'package:repo_aksomda_lifetownnightclub/features/stock/presentation/controllers/stock_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/main.dart';

import 'mocks/mock_auth_repository.dart';

class _FakeMenuRepository implements MenuRepository {
  @override
  Future<List<MenuItemEntity>> getMenu({bool forceRefresh = false}) async => [];
}

class _FakeOrderRepository implements OrderRepository {
  @override
  Future<List<OrderEntity>> getOrders() async => [];

  @override
  Future<OrderEntity> createOrder({
    String? tableId,
    String? waitressId,
    required List<OrderItem> items,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<OrderEntity> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeStockRepository implements StockRepository {
  @override
  Future<List<StockItemEntity>> getStocks() async => [];

  @override
  Future<StockItemEntity> updateQuantity({
    required String productId,
    required double quantity,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeStaffRepository implements StaffRepository {
  @override
  Future<List<WaitressEntity>> getWaitresses() async => [];

  @override
  Future<WaitressEntity> createWaitress({required String name, String? phone}) async {
    throw UnimplementedError();
  }

  @override
  Future<WaitressEntity> updateWaitress({
    required String id,
    required String name,
    String? phone,
    required bool active,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async => const DashboardSummary(
    products: 0,
    orders: 0,
    lowStocks: 0,
    staff: 0,
    revenue: 0,
  );
}

void main() {
  testWidgets('LifetownApp affiche l\'écran de connexion au démarrage', (
    WidgetTester tester,
  ) async {
    final authRepo = MockAuthRepository();
    final auth = AuthController(
      loginUseCase: Login(authRepo),
      registerUseCase: Register(authRepo),
      logoutUseCase: Logout(authRepo),
    );
    final menu = menu_feature.MenuController(getMenu: GetMenu(_FakeMenuRepository()));
    final orders = OrdersController(GetOrders(_FakeOrderRepository()));
    final stock = StockController(GetStocks(_FakeStockRepository()));
    final staff = StaffController(GetWaitresses(_FakeStaffRepository()));
    final dashboard = DashboardController(
      GetDashboard(_FakeDashboardRepository()),
    );

    await tester.pumpWidget(
      LifetownApp(
        auth: auth,
        menu: menu,
        orders: orders,
        stock: stock,
        staff: staff,
        dashboard: dashboard,
      ),
    );

    expect(find.text('LIFETOWN'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
