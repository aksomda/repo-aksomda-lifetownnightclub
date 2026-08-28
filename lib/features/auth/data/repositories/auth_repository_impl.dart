import '../../../../core/database/secure_token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureTokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  Future<User> _saveSession(Future<AuthResponseModel> request) async {
    final response = await request;
    await tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response.user;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) {
    return _saveSession(
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
    return _saveSession(
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

    final response = await remoteDataSource.refreshToken(
      refreshToken: refreshToken,
    );
    if (response.accessToken.isEmpty) {
      return null;
    }

    await tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken ?? refreshToken,
    );
    return response.accessToken;
  }
}
