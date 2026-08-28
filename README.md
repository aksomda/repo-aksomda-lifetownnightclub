# 🍺 LIFETOWN — App Flutter de gestion de maquis/nightclub

Application mobile Flutter connectée à une API REST réelle (FastAPI,
dépôt séparé `api_lifetown`) pour la gestion d'un maquis : catalogue de
boissons, stocks, serveuses et commandes, avec authentification JWT et
mode hors-ligne.

## 🩹 Corrections apportées (le projet ne compilait pas du tout)

Le code fourni initialement ne compilait pas et plusieurs écrans
n'existaient pas réellement. Corrections principales :

- **Imports cassés** (`core/storage/...` → `core/database/...`) dans
  `main.dart` et `core/network/auth_interceptor.dart`.
- **Fichiers dupliqués/vides à cheval entre `domain/` et `data/`**
  (violation de la Clean Architecture) : `auth_repository_impl.dart`,
  `auth_response_model.dart`, `menu_item_model.dart`,
  `menu_repository_impl.dart` — tout consolidé dans les bonnes couches.
- **`register_page.dart`** : les 4 champs (nom, prénom, âge, téléphone)
  partageaient le même `TextEditingController`, et l'appel à
  `register()` omettait 3 paramètres requis — réécrit avec un
  controller indépendant par champ.
- **`AuthRemoteDataSource.register()`** n'acceptait pas
  prénom/âge/téléphone alors que le reste du code les exigeait —
  corrigé.
- **`refresh_token_interceptor.dart`** était vide — implémenté (retry
  automatique sur 401, une seule requête de refresh à la fois).
- **`menu_page.dart`** ne contenait aucun widget (copie du
  controller) — remplacé par un vrai écran.
- **`hive_flutter`** manquant du `pubspec.yaml` — ajouté ; `provider`
  ajouté pour l'injection de dépendances entre écrans.
- **`main.dart`** ne naviguait nulle part (`Scaffold` vide) —
  reconstruit avec une vraie navigation Login/Register → Dashboard →
  Menu/Commandes/Stocks/Serveuses.
- Le `MenuItemModel` utilisait `@HiveType`/`@HiveField` avec un fichier
  `.g.dart` jamais généré (aucun `build_runner` n'avait tourné) —
  adapter Hive réécrit à la main, sans dépendance à la génération de
  code.

## ➕ Fonctionnalités ajoutées pour respecter l'énoncé

Le README d'origine promettait 5 écrans connectés à une API REST, mais
seules les couches `menu` et une partie de `auth` existaient
réellement. Couches **data + presentation complètes** ajoutées pour
`orders`, `stock`, `staff` (datasources, repository impl, controllers,
pages), avec 5 écrans réels connectés à l'API :

1. **Dashboard** — indicateurs agrégés (commandes en cours, stocks
   faibles, serveuses actives).
2. **Menu** — catalogue des boissons (bières & sucreries).
3. **Commandes** — historique + création de commandes.
4. **Stocks** — suivi et mise à jour des quantités.
5. **Serveuses** — liste + ajout.

## 🖥️ API réelle associée : `api_lifetown`

Cette application est câblée sur une API FastAPI dédiée (dépôt séparé).
Cette API a elle-même été **corrigée et alignée** sur le contrat exact
attendu par les datasources Dart ci-dessous (voir le README de
`api_lifetown` pour le détail des corrections apportées côté serveur :
bug de syntaxe bloquant, ajout de l'authentification JWT inexistante à
l'origine, renommage des routes/champs français → anglais).

| Feature Flutter | Route API | Auth requise |
|---|---|---|
| Auth | `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout` | non (sauf logout) |
| Menu | `GET /menu` | oui |
| Stock | `GET /stocks`, `PATCH /stocks/{id}` | oui |
| Serveuses | `GET/POST /staff`, `PUT /staff/{id}` | oui |
| Commandes | `GET/POST /orders`, `PATCH /orders/{id}/status` | oui |
| Tables | `GET/POST /tables` | oui (non consommé par un écran pour l'instant) |

Configurer l'URL de base dans `lib/core/constants/api_constants.dart` :

```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // émulateur Android -> API en local
```

## 🏛️ Architecture

Structure **Feature-First** combinée à la **Clean Architecture** :
- **Domain** : entités métier + contrats (interfaces de repository).
- **Data** : implémentation des repositories, modèles sérialisables,
  persistance locale (**Hive** pour le menu).
- **Presentation** : controllers (`ChangeNotifier`) + écrans, injectés
  via `provider`.

```
lib/
├── core/
│   ├── constants/          # api_constants.dart, lifetown_catalog.dart
│   ├── network/            # DioClient, AuthInterceptor, RefreshTokenInterceptor
│   ├── errors/              # AppException et sous-classes
│   └── database/            # SecureTokenStorage (flutter_secure_storage)
├── features/
│   ├── auth/        (data / domain / presentation)
│   ├── menu/         (data / domain / presentation) — cache Hive + mode hors-ligne
│   ├── orders/       (data / domain / presentation)
│   ├── stock/        (data / domain / presentation)
│   ├── staff/        (data / domain / presentation)
│   └── tables/       (domain seulement — non branché à un écran)
└── main.dart          # injection de dépendances + navigation
```

## 🚀 Fonctionnalités clés

1. **Authentification JWT** : login/register/logout, intercepteur Dio
   d'injection de token, refresh automatique sur 401.
2. **5 écrans connectés à l'API REST** (voir tableau ci-dessus).
3. **Cache local (Hive)** pour le menu, avec **bascule automatique sur
   le cache** en l'absence de réseau (bandeau "mode hors-ligne").
4. **Gestion d'erreurs réseau** avec messages utilisateur (pas de stack
   trace exposée).

## ⚙️ Configuration du projet

```bash
flutter pub get
flutter run
```

Aucune génération de code n'est requise (pas de `build_runner`) : les
adapters Hive sont écrits à la main dans
`lib/features/menu/data/models/menu_item_model.dart`.

## 🧪 Tests

```bash
flutter test
```

- `test/mocks/mock_auth_repository.dart` — `MockAuthRepository
  implements AuthRepository`, tel qu'explicitement demandé par
  l'énoncé.
- `test/auth_repository_test.dart` — 7 tests unitaires sur la couche
  repository (login, register, logout, refresh, cas d'échec).
- `test/menu_repository_test.dart` — 4 tests fonctionnels sur
  `MenuRepositoryImpl` avec de vrais fakes écrits à la main (pas de
  mockito/build_runner) et une vraie Hive Box en répertoire temporaire.
- `test/login_page_test.dart`, `test/register_page_test.dart`,
  `test/widget_test.dart` — tests widget (formulaires, affichage,
  gestion d'erreur).
- `test/api_connection_test.dart` — test de connexion Flutter ↔ API :
  exerce la vraie chaîne (`AuthInterceptor`, `SecureTokenStorage`,
  `AuthRemoteDataSource`, `AuthRepositoryImpl`) via un faux adaptateur
  HTTP Dio, sans backend réel.

## Limitations connues

- La feature `tables` n'a que sa couche domain : pas d'écran branché
  pour l'instant (l'API expose pourtant `/tables`).
- Pas de couche offline/cache pour `orders`/`stock`/`staff` (seul le
  menu bascule sur le cache Hive en mode hors-ligne).
- Pas de CI/CD (GitHub Actions) configuré sur ce dépôt.
