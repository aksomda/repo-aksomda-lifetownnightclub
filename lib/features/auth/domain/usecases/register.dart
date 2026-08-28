import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<User> call({
    required String name,
    required String prename,
    required int age,
    required String telephone,
    required String email,
    required String password,
  }) {
    return repository.register(
      name: name,
      prename: prename,
      age: age,
      telephone: telephone,
      email: email,
      password: password,
    );
  }
}
