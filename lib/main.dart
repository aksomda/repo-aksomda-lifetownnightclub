// Bug corrigé : `main.dart` n'initialisait pas Hive correctement
// (import `core/storage/...` inexistant), ne construisait aucun
// repository/controller pour menu/orders/stock/staff, et ne naviguait
// nulle part (`home: const Scaffold(body: Center(child: Text('LIFETOWN')))`).
// Reconstruit avec une vraie injection de dépendances (Provider) et une
// vraie navigation : Login/Register -> Dashboard -> Menu/Commandes/
// Stocks/Serveuses.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/database/secure_token_storage.dart';
import 'core/network/dio_client.dart';

import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/page/login_page.dart';
import 'features/auth/presentation/page/register_page.dart';

import 'features/menu/data/datasources/menu_local_datasource.dart';
import 'features/menu/data/datasources/menu_remote_datasource.dart';
import 'features/menu/data/models/menu_item_model.dart';
import 'features/menu/data/repositories/menu_repository_impl.dart';
import 'features/menu/domain/usecases/get_menu.dart';
import 'features/menu/presentation/controllers/menu_controller.dart';
import 'features/menu/presentation/pages/menu_page.dart';

import 'features/orders/data/datasources/order_remote_datasource.dart';
import 'features/orders/data/repositories/order_repository_impl.dart';
import 'features/orders/presentation/controllers/orders_controller.dart';
import 'features/orders/presentation/pages/orders_page.dart';

import 'features/stock/data/datasources/stock_remote_datasource.dart';
import 'features/stock/data/repositories/stock_repository_impl.dart';
import 'features/stock/presentation/controllers/stock_controller.dart';
import 'features/stock/presentation/pages/stock_page.dart';

import 'features/staff/data/datasources/staff_remote_datasource.dart';
import 'features/staff/data/repositories/staff_repository_impl.dart';
import 'features/staff/presentation/controllers/staff_controller.dart';
import 'features/staff/presentation/pages/staff_page.dart';

import 'features/dashboard/presentation/pages/dashboard_page.dart';

const String _menuBoxName = 'menu_box';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(MenuItemModelAdapter());
  final menuBox = await Hive.openBox<MenuItemModel>(_menuBoxName);

  final tokenStorage = SecureTokenStorage();
  final dioClient = DioClient(tokenStorage: tokenStorage);
  final Dio dio = dioClient.dio;

  // --- Auth ---
  final authRemoteDataSource = AuthRemoteDataSource(dio: dio);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    tokenStorage: tokenStorage,
  );
  final authController = AuthController(
    loginUseCase: Login(authRepository),
    registerUseCase: Register(authRepository),
    logoutUseCase: Logout(authRepository),
  );

  // --- Menu ---
  final menuRepository = MenuRepositoryImpl(
    remoteDataSource: MenuRemoteDataSource(dio: dio),
    localDataSource: MenuLocalDataSource(box: menuBox),
  );
  final menuController = MenuController(
    getMenu: GetMenu(menuRepository),
    repository: menuRepository,
  );

  // --- Orders ---
  final orderRepository = OrderRepositoryImpl(
    remoteDataSource: OrderRemoteDataSource(dio: dio),
  );
  final ordersController = OrdersController(repository: orderRepository);

  // --- Stock ---
  final stockRepository = StockRepositoryImpl(
    remoteDataSource: StockRemoteDataSource(dio: dio),
  );
  final stockController = StockController(repository: stockRepository);

  // --- Staff ---
  final staffRepository = StaffRepositoryImpl(
    remoteDataSource: StaffRemoteDataSource(dio: dio),
  );
  final staffController = StaffController(repository: staffRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: menuController),
        ChangeNotifierProvider.value(value: ordersController),
        ChangeNotifierProvider.value(value: stockController),
        ChangeNotifierProvider.value(value: staffController),
      ],
      child: const LifetownApp(),
    ),
  );
}

class LifetownApp extends StatelessWidget {
  const LifetownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LIFETOWN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

/// Route vers Login/Register tant qu'il n'y a pas d'utilisateur
/// authentifié, puis vers le tableau de bord principal une fois connecté.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isAuthenticated) {
      return const HomeShell();
    }

    if (_showRegister) {
      return RegisterPage(
        controller: auth,
        onLogin: () => setState(() => _showRegister = false),
      );
    }

    return LoginPage(
      controller: auth,
      onRegister: () => setState(() => _showRegister = true),
    );
  }
}

/// Coquille principale de l'application une fois connecté : navigation
/// par onglets entre Dashboard, Menu, Commandes, Stocks et Serveuses.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    DashboardPage(),
    MenuPage(),
    OrdersPage(),
    StockPage(),
    StaffPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_bar_outlined),
            selectedIcon: Icon(Icons.local_bar),
            label: 'Menu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stocks',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Serveuses',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.read<AuthController>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Déconnexion'),
            )
          : null,
    );
  }
}
