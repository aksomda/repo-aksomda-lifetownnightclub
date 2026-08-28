import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({required super.user, required super.accessToken, super.refreshToken});
  String get email => user.email;
  String get name => user.name;
  String get prename => user.prename;

  factory AuthResponseModel.fromJson(Map<String,dynamic> json) {
    final u = json['user'] is Map ? Map<String,dynamic>.from(json['user'] as Map) : <String,dynamic>{};
    return AuthResponseModel(user: User(id: '${u['id'] ?? ''}', name: '${u['name'] ?? ''}', prename: '${u['prename'] ?? ''}', age: (u['age'] as num?)?.toInt() ?? 0, telephone: '${u['telephone'] ?? ''}', email: '${u['email'] ?? ''}', role: u['role']?.toString()), accessToken: '${json['access_token'] ?? ''}', refreshToken: json['refresh_token']?.toString());
  }
}
