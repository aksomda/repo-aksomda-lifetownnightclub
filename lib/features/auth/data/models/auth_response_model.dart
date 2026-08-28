// Bug corrigé : ce fichier était vide. Le vrai modèle vivait par erreur
// dans `domain/entities/auth_response_model.dart`, ce qui viole la Clean
// Architecture (le domain ne doit pas connaître le JSON / la sérialisation
// réseau). Le contenu a été déplacé ici, dans la couche data.
import '../../domain/entities/user.dart';

class AuthResponseModel {
  final User user;
  final String accessToken;
  final String? refreshToken;

  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;

    return AuthResponseModel(
      user: User(
        id: userJson['id'].toString(),
        name: userJson['name'] as String? ?? '',
        prename: userJson['prename'] as String? ?? '',
        age: userJson['age'] as int? ?? 0,
        telephone: userJson['telephone'] as String? ?? '',
        email: userJson['email'] as String? ?? '',
        role: userJson['role'] as String?,
      ),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}
