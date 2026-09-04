import '../../../../core/database/secure_token_storage.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';

/// Implémente l'authentification et la persistance sécurisée de session.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureTokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  Future<User> saveSession(Future<AuthResponseModel> request) async {
    try {
      final response = await request;
      await tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return response.user;
    } catch (error) {
      throw mapDioException(error);
    }
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) {
    return saveSession(
      remoteDataSource.login(email: email, password: password),
    );
  }

  @override
  Future<User> register({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  }) {
    return saveSession(
      remoteDataSource.register(
        name: name,
        prename: prename,
        age: age,
        telephone: telephone,
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      await tokenStorage.clear();
    }
  }

  @override
  Future<String?> refreshToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      if (response.accessToken.isEmpty) {
        await tokenStorage.clear();
        throw const AppException('Impossible de renouveler la session.');
      }

      await tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken ?? refreshToken,
      );
      return response.accessToken;
    } catch (error) {
      await tokenStorage.clear();
      throw mapDioException(error);
    }
  }
}
