import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<User> register({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<String?> refreshToken();
}
