// Bug corrigé : ce fichier était le test par défaut généré par
// `flutter create` (un compteur "+1"), jamais adapté au projet : il
// référençait une classe `MyApp` qui n'a jamais existé ici (la vraie
// classe racine est `LifetownApp`, qui nécessite en plus une vraie
// initialisation Hive + Dio + Provider dans `main()`, incompatible avec
// un simple `pumpWidget` en test unitaire).
//
// Remplacé par un smoke test minimal et réellement pertinent : l'écran
// de connexion s'affiche correctement au démarrage de l'app pour un
// utilisateur non authentifié.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/login.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/logout.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/domain/usecases/register.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/controllers/auth_controller.dart';
import 'package:repo_aksomda_lifetownnightclub/features/auth/presentation/page/login_page.dart';

import 'mocks/mock_auth_repository.dart';

void main() {
  testWidgets(
    "l'écran de connexion s'affiche avec les champs Email et Mot de passe",
    (tester) async {
      final repository = MockAuthRepository();
      final controller = AuthController(
        loginUseCase: Login(repository),
        registerUseCase: Register(repository),
        logoutUseCase: Logout(repository),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(controller: controller, onRegister: () {}),
        ),
      );

      expect(find.text('LIFETOWN'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mot de passe'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Se connecter'), findsOneWidget);
    },
  );
}
