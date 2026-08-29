import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';

/// Orchestre l'état de l'authentification sans dépendre de Dio.
class AuthController extends ChangeNotifier {
  final Login loginUseCase;
  final Register registerUseCase;
  final Logout logoutUseCase;

  User? user;
  bool isLoading = false;
  String? errorMessage;

  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  });

  bool get isAuthenticated => user != null;

  /// Authentifie l'utilisateur et expose un message métier en cas d'échec.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      user = await loginUseCase(email: email, password: password);
      return true;
    } catch (error) {
      errorMessage = messageFrom(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Crée un compte utilisateur et ouvre sa session.
  Future<bool> register({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      user = await registerUseCase(
        name: name,
        prename: prename,
        age: age,
        telephone: telephone,
        email: email,
        password: password,
      );
      return true;
    } catch (error) {
      errorMessage = messageFrom(error);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Ferme la session locale, même si l'appel de déconnexion échoue.
  Future<void> logout() async {
    try {
      await logoutUseCase();
    } finally {
      user = null;
      notifyListeners();
    }
  }

  String messageFrom(Object error) {
    if (error is AppException) return error.message;
    return 'Une erreur inattendue est survenue. Veuillez réessayer.';
  }
}
