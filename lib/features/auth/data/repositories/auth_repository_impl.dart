// Bug corrigé : ce fichier était vide. L'implémentation réelle vivait par
// erreur dans `domain/repositories/auth_repository_impl.dart` — une
// implémentation concrète (qui parle à Dio et au stockage sécurisé) n'a
// rien à faire dans la couche domain, qui ne doit contenir que des
// contrats abstraits. Le contenu a été déplacé ici.
import '../../../../core/database/secure_token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureTokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
  });

  @override
  Future<User> login({required String email, required String password}) async {
    final result = await remoteDataSource.login(
      email: email,
      password: password,
    );

    await tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    return result.user;
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
    final result = await remoteDataSource.register(
      name: name,
      prename: prename,
      age: age,
      telephone: telephone,
      email: email,
      password: password,
    );

    await tokenStorage.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );

    return result.user;
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

    if (refreshToken == null) {
      return null;
    }

    final accessToken = await remoteDataSource.refreshToken(refreshToken);

    if (accessToken != null) {
      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    return accessToken;
  }
}
