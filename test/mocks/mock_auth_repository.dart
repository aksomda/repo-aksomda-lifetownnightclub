import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/entities/user.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldFail = false;

  User? currentUser;

  @override
  Future<User> login({required String email, required String password}) async {
    if (shouldFail) {
      throw Exception('Identifiants invalides');
    }

    final user = User(
      id: '1',
      name: 'Administrateur',
      prename: "Application",
      age: 43,
      telephone: "58871469",
      email: email,
      role: 'admin',
    );

    currentUser = user;

    return user;
  }

  @override
  Future<User> register({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw Exception('Erreur inscription');
    }

    final user = User(
      id: '2',
      name: name,
      prename: prename,
      age: age,
      telephone: telephone,
      email: email,
      role: 'user',
    );

    currentUser = user;

    return user;
  }

  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<String?> refreshToken() async {
    if (shouldFail) {
      return null;
    }

    return 'new-access-token';
  }
}
