# LIFETOWN — Gestion des stocks de boissons

Application Flutter de gestion d'un maquis/bar, conçue pour piloter le menu, les commandes, les stocks et les serveuses depuis une API REST.

## Fonctionnalités

- Authentification JWT : connexion, inscription et déconnexion.
- Injection automatique du JWT avec un intercepteur Dio.
- Renouvellement automatique du token après une réponse HTTP 401 lorsque le refresh token est disponible.
- Cinq écrans alimentés par API REST : **Tableau de bord, Menu, Commandes, Stocks, Serveuses**.
- Cache local Hive du menu.
- Consultation du menu depuis le cache lorsque l'API n'est pas accessible.
- Messages utilisateur pour les erreurs réseau, 401 et erreurs serveur.
- Catalogue initial des boissons :
  - Bières : Sobbra, Brakina, Beaufort, Castel, Guinness, Doppel, Brafort, Brafaso.
  - Sucreries : Schweppes, Coca, Fanta, Chill pomme, Chill citron.
- Tests de repository, tests widget et test de connexion Flutter ↔ API avec adaptateur HTTP Dio simulé.

## Architecture

Le projet suit une organisation **Feature-First + Clean Architecture**.

Chaque fonctionnalité est découpée en trois couches :

```text
lib/features/<feature>/
├── data/
│   ├── datasources/       # API REST et cache
│   ├── models/            # DTO / mapping JSON
│   └── repositories/      # implémentation des contrats
├── domain/
│   ├── entities/          # objets métier indépendants de Flutter/Dio
│   ├── repositories/      # contrats abstraits
│   └── usecases/          # cas d'utilisation
└── presentation/
    ├── controllers/       # état et orchestration UI
    └── pages/             # widgets / écrans
```

Le domaine ne dépend pas de Dio, Hive ou Flutter. Les implémentations techniques restent dans `data`.

## Écrans

1. **Connexion** — authentification.
2. **Inscription** — nom, prénom, âge, téléphone, email et mot de passe.
3. **Tableau de bord** — indicateurs remontés par `/dashboard`.
4. **Menu** — boissons et produits remontés par `/menu`, avec cache Hive.
5. **Commandes** — commandes remontées par `/orders`.
6. **Stocks** — niveaux de stock remontés par `/stocks`.
7. **Serveuses** — personnel remonté par `/staff`.

## Contrat API attendu

Par défaut :

```text
https://api.lifetown-maquis.com/v1
```

Il est recommandé de fournir l'URL réelle au build :

```bash
flutter run --dart-define=API_BASE_URL=https://mon-api.example.com/v1
```

Endpoints attendus :

```text
POST /auth/login
POST /auth/register
POST /auth/refresh
POST /auth/logout
GET  /dashboard
GET  /menu
GET  /orders
GET  /stocks
GET  /staff
```

Réponse d'authentification minimale :

```json
{
  "access_token": "jwt-access-token",
  "refresh_token": "jwt-refresh-token",
  "user": {
    "id": 1,
    "name": "Somda",
    "prename": "Clément",
    "age": 30,
    "telephone": "70000000",
    "email": "admin@lifetown.com",
    "role": "admin"
  }
}
```

Pour les listes, l'application accepte soit directement un tableau JSON, soit un objet contenant `data`.

## Persistance et mode hors-ligne

Hive est utilisé sans `build_runner` ni adaptateur généré. Le menu est sérialisé en JSON dans une `Box<String>`.

Lors d'un chargement normal :

1. si le menu est déjà en cache, il est affiché immédiatement ;
2. un rafraîchissement forcé interroge l'API ;
3. la réponse API remplace le cache ;
4. en cas d'échec réseau, le dernier cache disponible est retourné.

Le token JWT et le refresh token sont conservés séparément dans `flutter_secure_storage`.

## Tests

Lancer toute la suite :

```bash
flutter test
```

Analyse statique :

```bash
flutter analyze
```

La suite couvre notamment :

- 4 tests sur le comportement de `MockAuthRepository implements AuthRepository` ;
- 4 tests du `MenuRepositoryImpl` : API, cache, mode hors-ligne et absence simultanée d'API/cache ;
- 2 tests widget de connexion ;
- 1 test widget d'inscription ;
- 1 test de connexion Flutter ↔ API utilisant un faux `HttpClientAdapter` Dio et vérifiant l'injection `Authorization: Bearer ...`.

## Configuration du backend

Le backend reste indépendant de l'application Flutter. Une fois l'API créée, il suffit de respecter les endpoints et les structures JSON décrites ci-dessus, puis de fournir `API_BASE_URL` au lancement.

Pour une mise en production, il est recommandé d'ajouter :

- validation stricte des schémas JSON côté client et serveur ;
- pagination des commandes et du stock ;
- journalisation centralisée sans données sensibles ;
- gestion d'une file de synchronisation pour les écritures hors-ligne ;
- CI GitHub Actions avec `flutter analyze` et `flutter test` ;
- tests d'intégration contre un environnement API de recette.

## Validation de l'architecture

Les implémentations de repository appartiennent exclusivement à `data/repositories`.
Les modèles JSON appartiennent à `data/models`. Les entités et interfaces de repository
restent dans `domain`.

Ne pas recréer les anciens fichiers suivants dans `domain` :
- `auth_repository_impl.dart`
- `auth_response_model.dart`
- `menu_item_model.dart`
- `menu_repository_impl.dart`

Le projet n'utilise pas de fichier `menu_item_model.g.dart` : le cache Hive est sérialisé
explicitement afin d'éviter une dépendance à `build_runner`.

## Vérification locale

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

Pour vérifier l'API réelle :

```bash
flutter run --dart-define=API_BASE_URL=https://votre-api.example.com/v1
```
