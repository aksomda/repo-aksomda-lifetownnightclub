# LIFETOWN — Gestion des stocks de boissons

Application Flutter de gestion d'un maquis/bar, conçue pour piloter le menu, les commandes, les stocks et les serveuses depuis une API REST.

## Fonctionnalités

- Authentification JWT : connexion, inscription et déconnexion.
- Injection automatique du JWT avec un intercepteur Dio.
- Renouvellement automatique du token après une réponse HTTP 401 lorsque le refresh token est disponible.
- Cinq écrans alimentés par API REST : **Tableau de bord, Menu, Commandes, Stocks, Serveuses**.
- Cache local Hive **pour les cinq écrans** (menu, commandes, stocks, personnel, tableau de bord).
- Consultation des cinq écrans depuis le cache lorsque l'API n'est pas accessible (mode hors-ligne).
- Messages utilisateur conviviaux pour les erreurs réseau, 401 et erreurs serveur, via `mapDioException` appelé de façon cohérente dans les cinq repositories.
- Écriture complète du contrat API : mise à jour d'un stock, changement de statut d'une commande, création/mise à jour d'une serveuse (plus seulement la lecture).
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

Endpoints attendus (implémentés par le backend FastAPI fourni séparément, dossier `api_lifetown/`) :

```text
POST  /auth/login
POST  /auth/register
POST  /auth/refresh
POST  /auth/logout
GET   /dashboard
GET   /menu
GET   /orders
POST  /orders
PATCH /orders/{id}/status
GET   /stocks
PATCH /stocks/{productId}
GET   /staff
POST  /staff
PATCH /staff/{id}
```

Toutes les routes sauf `/auth/*` exigent l'en-tête `Authorization: Bearer <access_token>`
(ajouté automatiquement par `AuthInterceptor`).

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

Hive est utilisé sans `build_runner` ni adaptateur généré. Chaque feature sérialise ses
données en JSON dans la même `Box<String>` (`lifetown_cache`), sous une clé dédiée :

| Feature   | Datasource locale             | Clé Hive    |
|-----------|--------------------------------|-------------|
| Menu      | `MenuLocalDataSource`          | `menu`      |
| Commandes | `OrderLocalDataSource`         | `orders`    |
| Stocks    | `StockLocalDataSource`         | `stocks`    |
| Personnel | `StaffLocalDataSource`         | `staff`     |
| Dashboard | `DashboardLocalDataSource`     | `dashboard` |

Chacun des 5 repository impls suit exactement le même pattern (`getMenu`, `getOrders`,
`getStocks`, `getWaitresses`, `getSummary`) :

1. tente l'appel réseau ;
2. en cas de succès, met à jour le cache local et retourne la donnée fraîche ;
3. en cas d'échec (pas de réseau, timeout, erreur serveur), retourne le dernier cache
   disponible s'il existe ;
4. si l'API échoue **et** qu'aucun cache n'existe, remonte une `AppException` avec un
   message utilisateur clair (`mapDioException`, défini dans `core/network/dio_client.dart`).

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
- 4 tests du `StockRepositoryImpl` (même pattern : API, cache, hors-ligne, erreur) ;
- 4 tests de l'`OrderRepositoryImpl` (même pattern) ;
- 2 tests widget de connexion ;
- 1 test widget d'inscription ;
- 1 test smoke sur l'entité `User` ;
- 1 test smoke sur `LifetownApp` avec ses 6 contrôleurs et repositories factices ;
- 1 test de connexion Flutter ↔ API utilisant un faux `HttpClientAdapter` Dio et vérifiant l'injection `Authorization: Bearer ...`.

Soit 22 tests au total : 16 sur la couche repository (largement au-dessus des 4 minimum
requis), 5 tests fonctionnels/widgets et 1 test de connexion Flutter ↔ API.

## Configuration du backend

Le backend FastAPI qui implémente exactement ce contrat est livré séparément
(dossier `api_lifetown/`, voir son propre README pour l'installation).

Pour le lancer en local puis connecter l'application Flutter dessus :

```bash
# 1) démarrer l'API (voir api_lifetown/README.md pour le détail)
cd api_lifetown
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 2) lancer Flutter en pointant vers cette API
cd ../repo-aksomda-lifetownnightclub
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1   # émulateur Android
flutter run --dart-define=API_BASE_URL=http://localhost:8000/v1  # simulateur iOS / web
flutter run --dart-define=API_BASE_URL=http://<ip-machine>:8000/v1 # appareil physique
```

Un compte de démonstration est créé automatiquement au premier démarrage de l'API :
`admin@lifetown.com` / `password`.

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
