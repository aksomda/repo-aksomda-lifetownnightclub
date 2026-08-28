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
        age: userJson['age'] as int,
        telephone: userJson['telephone'] as String? ?? '',
        email: userJson['email'] as String? ?? '',
        role: userJson['role'] as String?,
      ),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}
