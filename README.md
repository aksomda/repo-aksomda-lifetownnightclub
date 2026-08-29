# LIFETOWN — Application Flutter de gestion

Application Flutter de gestion d'un maquis / espace de restauration LIFETOWN.
Le projet est organisé selon une approche **Feature-First + Clean Architecture** et
communique avec une API REST sécurisée par JWT.

Cette version met l'accent sur quatre objectifs de qualité :

1. **Continuité de service** : le Menu, les Commandes, les Stocks, le Personnel et le
   Dashboard disposent d'un cache local Hive utilisable lorsque l'API est indisponible.
2. **Robustesse réseau** : les erreurs Dio sont converties en messages métier clairs et
   cohérents.
3. **Sécurité d'authentification** : le JWT d'accès est stocké dans
   `flutter_secure_storage`, n'est pas envoyé aux routes publiques d'authentification et
   peut être renouvelé automatiquement grâce au refresh token.
4. **Testabilité** : les repositories, le cache, la sérialisation, les erreurs,
   l'authentification et les principaux écrans sont couverts par des tests.

---

## 1. Fonctionnalités

### Authentification

- Connexion par email et mot de passe.
- Inscription avec nom, prénom, âge, téléphone, email et mot de passe.
- Stockage sécurisé de l'access token et du refresh token.
- Injection automatique du JWT sur les routes protégées.
- Rafraîchissement automatique du JWT lorsqu'une requête protégée reçoit un `401`.
- Verrouillage des rafraîchissements concurrents : plusieurs requêtes expirées
  partagent le même refresh en cours.
- Suppression des tokens lorsque le refresh échoue ou lors de la déconnexion.

### Écrans métier

1. Tableau de bord.
2. Menu.
3. Commandes.
4. Stocks.
5. Personnel / serveuses.

Les cinq écrans métier consomment des données provenant de l'API et disposent d'une
stratégie de cache pour les lectures.

---

## 2. Architecture

Le projet suit une organisation Feature-First :

```text
lib/
├── core/
│   ├── constants/
│   ├── database/
│   ├── errors/
│   └── network/
│
└── features/
    ├── auth/
    ├── dashboard/
    ├── menu/
    ├── orders/
    ├── staff/
    ├── stock/
    └── tables/
```

Chaque fonctionnalité métier suit autant que possible les trois couches suivantes :

```text
features/<feature>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── pages/
    └── widgets/
```

### Règles de dépendance

- `domain` ne dépend ni de Dio, ni de Hive, ni de Flutter.
- `data` implémente les contrats du `domain`.
- Les `remote datasource` sont responsables des appels HTTP et du mapping JSON.
- Les `local datasource` sont responsables de la persistance Hive.
- Les repositories orchestrent réseau, cache et traduction des erreurs.
- Les controllers orchestrent l'état de l'interface et ne connaissent pas les détails de
  Dio ou de Hive.
- Les pages Flutter consomment les controllers.

Cette séparation facilite les tests unitaires et limite le couplage entre l'interface,
le réseau et la persistance.

---

## 3. Stratégie réseau + cache

Le cache local est implémenté avec Hive et une seule `Box<String>` nommée
`lifetown_cache`.

| Fonctionnalité | Datasource locale | Clé Hive |
|---|---|---|
| Menu | `MenuLocalDataSource` | `menu` |
| Commandes | `OrderLocalDataSource` | `orders` |
| Stocks | `StockLocalDataSource` | `stocks` |
| Personnel | `StaffLocalDataSource` | `staff` |
| Dashboard | `DashboardLocalDataSource` | `dashboard` |

Les données sont sérialisées explicitement en JSON. Aucun `build_runner` ni adaptateur
Hive généré n'est nécessaire.

### Lecture

Tous les repositories de lecture utilisent le même contrat :

```text
API
 │
 ├── succès ──> sauvegarde Hive ──> données fraîches
 │
 └── échec
       │
       ├── cache valide ──> données locales
       │
       └── cache absent/invalide ──> AppException conviviale
```

Ainsi, une coupure réseau ne vide pas l'écran si une dernière version valide des données
est disponible.

Le cache est également mis à jour après les opérations d'écriture réussies lorsqu'une
copie locale existe :

- création d'une commande ;
- changement de statut d'une commande ;
- modification d'une quantité de stock ;
- création d'une serveuse ;
- modification d'une serveuse.

### Important : limite volontaire du mode hors-ligne

Le mode hors-ligne couvre la **consultation** des données et la conservation locale de
la dernière version connue. Les écritures nécessitent encore une connexion au serveur.

Une évolution future pourra introduire une file de synchronisation locale pour permettre
la création/modification hors connexion avec résolution des conflits.

---

## 4. Sérialisation des modèles

Les quatre modèles concernés par le cache disposent d'un `toJson()` explicite :

- `OrderModel`
- `StockItemModel`
- `WaitressModel`
- `DashboardSummaryModel`

`MenuItemModel` disposait déjà de cette capacité.

Chaque modèle expose également `fromJson()` afin de reconstituer les objets métier après
lecture du cache.

Exemple conceptuel :

```text
objet métier
   ↓
Model.toJson()
   ↓
jsonEncode()
   ↓
Hive
   ↓
jsonDecode()
   ↓
Model.fromJson()
   ↓
repository
```

Les datasources locales considèrent un JSON corrompu comme un cache invalide. Elles ne
laissent pas une `FormatException` technique remonter jusqu'à l'interface.

---

## 5. Gestion des erreurs

La fonction centrale `mapDioException()` transforme les erreurs techniques en
`AppException`.

Les principaux scénarios sont couverts :

| Situation | Message / type |
|---|---|
| Pas de connexion | `NetworkException` |
| Timeout connexion | `NetworkException` |
| Timeout envoi/réception | `NetworkException` |
| Certificat invalide | erreur réseau conviviale |
| HTTP 401 | `UnauthorizedException` |
| HTTP 403 | `ForbiddenException` |
| HTTP 404 | `NotFoundException` |
| HTTP 409 | message métier fourni par l'API |
| HTTP 422 | message de validation fourni par l'API |
| HTTP 5xx | `ServerException` |
| Erreur inattendue | message générique sans détails techniques |

Les formats courants du backend sont pris en charge :

```json
{"message": "Stock insuffisant"}
```

```json
{"error": "Opération impossible"}
```

```json
{"detail": "Données invalides"}
```

ainsi que les erreurs de validation de type FastAPI :

```json
{
  "detail": [
    {"msg": "field required"}
  ]
}
```

Une erreur interne ou une exception technique inattendue n'est pas affichée brute à
l'utilisateur. Cela évite notamment de présenter une stack trace, un nom de classe ou
un détail interne du client HTTP dans l'interface.

---

## 6. Authentification et JWT

Les tokens sont stockés avec `flutter_secure_storage`.

```text
SecureTokenStorage
├── access_token
└── refresh_token
```

### Injection du token

`AuthInterceptor` ajoute :

```text
Authorization: Bearer <access_token>
```

uniquement aux routes protégées.

Les routes suivantes sont explicitement publiques :

```text
/auth/login
/auth/register
/auth/refresh
```

Elles ne reçoivent donc pas un ancien JWT par inadvertance.

### Refresh automatique

Lorsqu'une requête protégée reçoit `401` :

```text
requête protégée
      ↓
     401
      ↓
refresh token disponible ?
   ├── non → erreur 401
   └── oui
       ↓
POST /auth/refresh
       ↓
nouvel access token
       ↓
sauvegarde des tokens
       ↓
rejeu de la requête initiale
```

Le mécanisme évite les rafraîchissements concurrents grâce à un `Completer`. Si plusieurs
requêtes expirent simultanément, une seule opération de refresh est exécutée et les
autres attendent son résultat.

Si le refresh échoue, les tokens sont supprimés et l'erreur initiale est transmise au
repository.

---

## 7. Contrat API

Par défaut :

```text
https://api.lifetown-maquis.com/v1
```

L'URL peut être remplacée au lancement :

```bash
flutter run --dart-define=API_BASE_URL=https://mon-api.example.com/v1
```

### Endpoints

```text
POST   /auth/login
POST   /auth/register
POST   /auth/refresh
POST   /auth/logout

GET    /dashboard

GET    /menu

GET    /orders
POST   /orders
PATCH  /orders/{id}/status

GET    /stocks
PATCH  /stocks/{productId}

GET    /staff
POST   /staff
PATCH  /staff/{id}
```

Toutes les routes métier nécessitent :

```text
Authorization: Bearer <access_token>
```

Le client accepte pour les listes :

```json
[
  {}
]
```

ou :

```json
{
  "data": [
    {}
  ]
}
```

Pour les réponses de synthèse, il accepte également un objet encapsulé dans `data`.

### Authentification minimale

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

---

## 8. Injection des dépendances

`main.dart` initialise les dépendances dans un ordre explicite :

```text
Hive
 ↓
SecureTokenStorage
 ↓
DioClient
 ↓
RemoteDataSource + LocalDataSource
 ↓
RepositoryImpl
 ↓
UseCase
 ↓
Controller
 ↓
LifetownApp
```

Les cinq repositories disposent désormais d'un datasource local :

```dart
MenuRepositoryImpl(
  remote: MenuRemoteDataSource(dio: client.dio),
  local: MenuLocalDataSource(box: box),
)
```

Le même principe est utilisé pour les commandes, le stock, le personnel et le dashboard.

Cette composition rend les repositories facilement remplaçables par des fakes ou des
mocks pendant les tests.

---

## 9. Tests

La stratégie de test ne se limite plus aux quatre tests minimum par repository.

### Tests de repositories

La suite comporte désormais **52 tests**. Les suites vérifient notamment :

- appel API réussi ;
- sauvegarde du résultat dans Hive ;
- retour du cache lorsque l'API échoue ;
- erreur lorsque API et cache sont indisponibles ;
- synchronisation du cache après création/modification ;
- conservation des données après mise à jour du statut ;
- gestion du cache corrompu.

Les fonctionnalités couvertes sont :

```text
Menu
Commandes
Stocks
Personnel
Dashboard
```

### Tests de sérialisation

Les modèles sont testés avec des scénarios aller-retour :

```text
Model → JSON → Model
```

pour :

- commandes ;
- stocks ;
- personnel ;
- dashboard.

### Tests réseau

Le client Dio est testé avec un adaptateur HTTP simulé pour vérifier :

- absence de JWT sur `/auth/login` ;
- absence de JWT sur `/auth/refresh` ;
- injection du JWT sur une route protégée ;
- réception d'un `401` ;
- appel automatique du refresh token ;
- remplacement du token ;
- rejeu de la requête initiale avec le nouveau token.

### Tests d'erreurs

Les codes 401, 403, 409, 422, timeout et exceptions inattendues sont couverts.

### Tests widgets

Les principaux écrans sont testés pour vérifier qu'ils :

- se construisent correctement ;
- déclenchent le chargement ;
- affichent les données retournées par leur controller ;
- affichent les informations métier importantes ;
- signalent notamment un stock faible.

### Exécution

```bash
flutter test
```

Analyse statique :

```bash
flutter analyze
```

---

## 10. Intégration continue

Le workflow GitHub Actions situé dans :

```text
.github/workflows/flutter.yml
```

exécute automatiquement :

```text
flutter pub get
flutter analyze
flutter test
```

sur les push et pull requests.

Il est recommandé de conserver cette vérification obligatoire avant toute fusion vers
la branche principale.

---

## 11. Lancer l'application

### Prérequis

- Flutter stable ;
- Dart compatible avec le SDK indiqué dans `pubspec.yaml` ;
- accès à l'API LIFETOWN ou au backend local.

Installer les dépendances :

```bash
flutter pub get
```

Lancer l'analyse :

```bash
flutter analyze
```

Lancer les tests :

```bash
flutter test
```

Lancer l'application :

```bash
flutter run
```

Avec une API locale :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1
```

Pour un appareil physique, remplacer `10.0.2.2` par l'adresse IP accessible de la machine
hébergeant l'API.

---

## 12. Connexion Flutter ↔ API locale

Si le backend FastAPI est disponible dans un dossier voisin nommé `api_lifetown` :

```bash
cd api_lifetown
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Puis, dans le projet Flutter :

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1
```

### Attention selon la plateforme

| Plateforme | URL typique |
|---|---|
| Android Emulator | `http://10.0.2.2:8000/v1` |
| iOS Simulator | `http://localhost:8000/v1` |
| Web | `http://localhost:8000/v1` |
| Appareil physique | `http://<IP-DE-LA-MACHINE>:8000/v1` |

---

## 13. Sécurité du dépôt

Ne jamais committer :

- clé privée SSH ;
- fichier `.env` contenant des secrets ;
- mots de passe de production ;
- tokens JWT ;
- certificats ou clés privées ;
- identifiants d'accès à une infrastructure.

Les fichiers générés tels que `.dart_tool`, `build` et les fichiers de configuration
locaux ne doivent pas être distribués avec le code source.

**Point critique :** si une clé privée a déjà été commitée dans l'historique Git, la
suppression du fichier dans le dernier commit ne suffit pas. La clé doit être considérée
comme compromise : il faut la révoquer/remplacer côté GitHub et sur tous les serveurs où
elle est autorisée, puis nettoyer l'historique Git si nécessaire.

---

## 14. Limites actuelles et évolutions recommandées

### Synchronisation des écritures hors ligne

Le cache actuel est conçu pour la lecture. Pour une véritable application offline-first,
il faudra ajouter :

```text
Action utilisateur
      ↓
Base locale
      ↓
file d'opérations
      ↓
réseau disponible ?
   ├── non → attente
   └── oui → synchronisation API
                 ↓
              succès
                 ↓
          suppression de la file
```

Cette évolution devra prévoir :

- identifiant local temporaire ;
- statut `pending/synced/failed` ;
- nombre de tentatives ;
- reprise après redémarrage ;
- résolution des conflits ;
- idempotence côté API.

### Pagination

Les commandes et éventuellement les stocks devraient être paginés lorsque le volume
de données augmente.

### Observabilité

Ajouter une journalisation structurée côté application et serveur, sans jamais écrire
de mots de passe, tokens ou données sensibles dans les logs.

### CI/CD

Le workflow de base est présent. Une évolution professionnelle pourra ajouter :

- couverture de tests ;
- génération de rapports ;
- build Android/iOS ;
- analyse des dépendances ;
- vérification de secrets ;
- déploiement vers un environnement de recette.

### Validation des contrats

Des tests de contrat API peuvent être ajoutés pour détecter rapidement une divergence
entre les modèles Flutter et le backend.

---

## 15. Checklist de qualité

Avant une livraison :

```text
[ ] flutter pub get
[ ] flutter analyze
[ ] flutter test
[ ] aucune clé privée dans le dépôt
[ ] aucun secret dans les fichiers source
[ ] API_BASE_URL configurée pour l'environnement cible
[ ] refresh token testé
[ ] comportement 401 testé
[ ] comportement hors-ligne testé
[ ] cache corrompu testé
[ ] écrans principaux testés
[ ] contrat API documenté
```

---

## 16. Résumé des améliorations apportées

Cette version répond aux principaux points soulevés lors de l'évaluation :

- cache local étendu aux cinq écrans métier ;
- `toJson()` disponible sur les modèles nécessaires au cache ;
- stratégie repository réseau → cache → erreur harmonisée ;
- implémentation réelle des opérations stock, commandes et personnel ;
- synchronisation du cache après les écritures réussies ;
- injection des datasources locaux centralisée dans `main.dart` ;
- gestion plus complète des erreurs Dio ;
- suppression de la dépendance Dio dans les controllers de présentation ;
- protection des routes publiques d'authentification contre l'injection d'un JWT ;
- refresh token automatique avec protection contre les refresh concurrents ;
- tests repositories supplémentaires ;
- tests de sérialisation ;
- tests du mapping d'erreurs ;
- tests du refresh JWT ;
- tests widgets des cinq écrans ;
- traitement des caches JSON corrompus ;
- CI `flutter analyze` + `flutter test` ;
- documentation renforcée sur l'architecture, le cache, le contrat API, la sécurité et
  les limites du mode hors-ligne.

Le projet constitue ainsi une base nettement plus robuste et maintenable. La prochaine
étape de niveau production est principalement la synchronisation offline-first des
écritures et l'augmentation progressive des tests d'intégration contre une API de
recette.
