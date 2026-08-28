// Réécrit entièrement : le fichier d'origine était une coquille vide,
// sans `void main()`, donc jamais exécutée par `flutter test` (elle
// aurait même empêché la compilation de la suite de tests).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/login.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/logout.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/register.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/page/login_page.dart';

import 'mocks/mock_auth_repository.dart';

AuthController _buildController(MockAuthRepository repository) {
  return AuthController(
    loginUseCase: Login(repository),
    registerUseCase: Register(repository),
    logoutUseCase: Logout(repository),
  );
}

void main() {
  testWidgets(
    "l'utilisateur peut se connecter avec des identifiants valides",
    (tester) async {
      final repository = MockAuthRepository();
      final controller = _buildController(repository);
      var registerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            controller: controller,
            onRegister: () => registerTapped = true,
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'admin@lifetown.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
      await tester.pump(); // démarre l'appel async (isLoading = true)
      await tester.pump(); // laisse le Future du mock se résoudre

      expect(controller.isAuthenticated, isTrue);
      expect(controller.user?.email, 'admin@lifetown.com');
      expect(registerTapped, isFalse);
    },
  );

  testWidgets(
    'un message d\'erreur est affiché quand la connexion échoue',
    (tester) async {
      final repository = MockAuthRepository()..shouldFail = true;
      final controller = _buildController(repository);

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(controller: controller, onRegister: () {}),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'bad@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
      await tester.pump();
      await tester.pump();

      expect(controller.isAuthenticated, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );
}
