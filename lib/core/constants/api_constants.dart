class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.lifetown-maquis.com/v1';

  // Authentification
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Menu
  static const String menu = '/menu';

  // Commandes
  static const String orders = '/orders';

  // Stocks
  static const String stocks = '/stocks';

  // Serveuses
  static const String staff = '/staff';

  // Tables
  static const String tables = '/tables';

  // Tableau de bord
  static const String dashboard = '/dashboard';
}
