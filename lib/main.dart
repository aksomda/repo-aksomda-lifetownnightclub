import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/database/secure_token_storage.dart';
import 'core/network/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/menu/data/datasources/menu_local_datasource.dart';
import 'features/menu/data/datasources/menu_remote_datasource.dart';
import 'features/menu/data/repositories/menu_repository_impl.dart';
import 'features/menu/domain/usecases/get_menu.dart';
import 'features/menu/presentation/controllers/menu_controller.dart'
    as menu_feature;
import 'features/menu/presentation/pages/menu_page.dart';
import 'features/orders/data/datasources/order_remote_datasource.dart';
import 'features/orders/data/repositories/order_repository_impl.dart';
import 'features/orders/domain/usecases/get_orders.dart';
import 'features/orders/presentation/controllers/orders_controller.dart';
import 'features/orders/presentation/pages/orders_page.dart';
import 'features/stock/data/datasources/stock_remote_datasource.dart';
import 'features/stock/data/repositories/stock_repository_impl.dart';
import 'features/stock/domain/usecases/get_stocks.dart';
import 'features/stock/presentation/controllers/stock_controller.dart';
import 'features/stock/presentation/pages/stock_page.dart';
import 'features/staff/data/datasources/staff_remote_datasource.dart';
import 'features/staff/data/repositories/staff_repository_impl.dart';
import 'features/staff/domain/usecases/get_waitresses.dart';
import 'features/staff/presentation/controllers/staff_controller.dart';
import 'features/staff/presentation/pages/staff_page.dart';
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/usecases/get_dashboard.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox<String>('lifetown_cache');
  final storage = SecureTokenStorage();
  final client = DioClient(tokenStorage: storage);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(dio: client.dio),
    tokenStorage: storage,
  );
  final auth = AuthController(
    loginUseCase: Login(authRepository),
    registerUseCase: Register(authRepository),
    logoutUseCase: Logout(authRepository),
  );
  final menu = menu_feature.MenuController(
    getMenu: GetMenu(
      MenuRepositoryImpl(
        remote: MenuRemoteDataSource(dio: client.dio),
        local: MenuLocalDataSource(box: box),
      ),
    ),
  );
  final orders = OrdersController(
    GetOrders(
      OrderRepositoryImpl(remote: OrderRemoteDataSource(dio: client.dio)),
    ),
  );
  final stock = StockController(
    GetStocks(StockRepositoryImpl(StockRemoteDataSource(dio: client.dio))),
  );
  final staff = StaffController(
    GetWaitresses(StaffRepositoryImpl(StaffRemoteDataSource(client.dio))),
  );
  final dash = DashboardController(
    GetDashboard(
      DashboardRepositoryImpl(DashboardRemoteDataSource(client.dio)),
    ),
  );
  runApp(
    LifetownApp(
      auth: auth,
      menu: menu,
      orders: orders,
      stock: stock,
      staff: staff,
      dashboard: dash,
    ),
  );
}

class LifetownApp extends StatefulWidget {
  final AuthController auth;
  final menu_feature.MenuController menu;
  final OrdersController orders;
  final StockController stock;
  final StaffController staff;
  final DashboardController dashboard;
  const LifetownApp({
    super.key,
    required this.auth,
    required this.menu,
    required this.orders,
    required this.stock,
    required this.staff,
    required this.dashboard,
  });
  @override
  State<LifetownApp> createState() => _LifetownAppState();
}

class _LifetownAppState extends State<LifetownApp> {
  int index = 0;
  bool register = false;
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_authChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_authChanged);
    super.dispose();
  }

  void _authChanged() => mounted ? setState(() {}) : null;
  Future<void> logout() async {
    await widget.auth.logout();
    if (mounted) {
      setState(() {
        index = 0;
        register = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LIFETOWN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: widget.auth.isAuthenticated
          ? _shell()
          : register
          ? RegisterPage(
              controller: widget.auth,
              onLogin: () => setState(() => register = false),
            )
          : LoginPage(
              controller: widget.auth,
              onRegister: () => setState(() => register = true),
            ),
    );
  }

  Widget _shell() {
    final pages = [
      DashboardPage(
        controller: widget.dashboard,
        onLogout: logout,
        onNavigate: (i) => setState(() => index = i),
      ),
      MenuPage(controller: widget.menu),
      OrdersPage(controller: widget.orders),
      StockPage(controller: widget.stock),
      StaffPage(controller: widget.staff),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.local_bar), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Commandes'),
          NavigationDestination(icon: Icon(Icons.inventory), label: 'Stocks'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Serveuses'),
        ],
      ),
    );
  }
}
