import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/entities/user.dart';

void main() {
  test('les entités métier sont instanciables', () {
    const user = User(
      id: '1',
      name: 'Somda',
      prename: 'Clément',
      age: 30,
      telephone: '70000000',
      email: 'admin@lifetown.com',
    );

    expect(user.email, 'admin@lifetown.com');
    expect(user.age, 30);
  });
}
