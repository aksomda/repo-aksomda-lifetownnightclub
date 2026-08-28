// Ajouté : n'existait pas dans le projet d'origine.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/login.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/logout.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/register.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/page/register_page.dart';

import 'mocks/mock_auth_repository.dart';

void main() {
  testWidgets(
    'chaque champ du formulaire est indépendant et register() reçoit '
    'tous les paramètres requis',
    (tester) async {
      final repository = MockAuthRepository();
      final controller = AuthController(
        loginUseCase: Login(repository),
        registerUseCase: Register(repository),
        logoutUseCase: Logout(repository),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RegisterPage(controller: controller, onLogin: () {}),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Nom'), 'Traoré');
      await tester.enterText(find.widgetWithText(TextFormField, 'Prénom'), 'Awa');
      await tester.enterText(find.widgetWithText(TextFormField, 'Âge'), '24');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Numéro de téléphone'),
        '70000000',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'awa@lifetown.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mot de passe'),
        'password',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Créer le compte'));
      await tester.pump();
      await tester.pump();

      // Si les 4 premiers champs partageaient encore le même controller
      // (bug d'origine), `name` == `prename` == `age` == `telephone` et
      // ce test échouerait.
      expect(controller.isAuthenticated, isTrue);
      expect(controller.user?.name, 'Traoré');
      expect(controller.user?.prename, 'Awa');
      expect(controller.user?.age, 24);
      expect(controller.user?.telephone, '70000000');
      expect(controller.user?.email, 'awa@lifetown.com');
    },
  );
}
