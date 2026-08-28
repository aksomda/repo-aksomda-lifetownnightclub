import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_auth_repository.dart';

// Étoffé (par rapport à l'original) : le pattern `MockAuthRepository
// implements AuthRepository` était explicitement demandé par l'énoncé du
// projet ; on garde ce fichier et on ajoute des cas manquants
// (inscription, refresh en échec, état initial).
void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  test('login réussit avec des identifiants valides', () async {
    final user = await repository.login(
      email: 'admin@lifetown.com',
      password: 'password',
    );

    expect(user.email, 'admin@lifetown.com');
    expect(repository.currentUser, isNotNull);
  });

  test('login échoue avec des identifiants invalides', () async {
    repository.shouldFail = true;

    expect(
      () => repository.login(email: 'bad@test.com', password: 'bad'),
      throwsException,
    );
  });

  test('logout supprime la session', () async {
    await repository.login(email: 'admin@lifetown.com', password: 'password');

    await repository.logout();

    expect(repository.currentUser, isNull);
  });

  test('refresh retourne un nouveau token', () async {
    final token = await repository.refreshToken();

    expect(token, isNotNull);
  });

  // --- Ajouté ---

  test('aucune session active avant tout login', () {
    expect(repository.currentUser, isNull);
  });

  test('register réussit et ouvre une session avec toutes les infos', () async {
    final user = await repository.register(
      name: 'Traoré',
      prename: 'Awa',
      age: 24,
      telephone: '70000000',
      email: 'awa@lifetown.com',
      password: 'password',
    );

    expect(user.name, 'Traoré');
    expect(user.prename, 'Awa');
    expect(user.age, 24);
    expect(repository.currentUser, isNotNull);
  });

  test('register échoue proprement quand shouldFail est activé', () async {
    repository.shouldFail = true;

    expect(
      () => repository.register(
        name: 'X',
        prename: 'Y',
        age: 20,
        telephone: '00000000',
        email: 'x@test.com',
        password: 'password',
      ),
      throwsException,
    );
  });

  test('refresh retourne null quand shouldFail est activé', () async {
    repository.shouldFail = true;

    final token = await repository.refreshToken();

    expect(token, isNull);
  });
}
