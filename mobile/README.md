# Covoit'Go - Application Mobile (Flutter)

Application mobile multiplateforme (Android / iOS) développée avec le framework **Flutter** et le langage **Dart**, conçue pour les passagers et les conducteurs de la plateforme Covoit'Go.

---

## Points Clés de l'Application

- **Double Rôle Utilisateur :** Interface adaptative pour le Passager (recherche géolocalisée, réservation) et le Conducteur (création de trajets, gestion et validation des demandes).
- **Architecture Offline-First :** Persistance locale des données avec **SQLite** (`sqflite`). L'utilisateur peut consulter ses trajets et initier des réservations même en zone blanche (sans réseau).
- **Service de Synchronisation Automatique :** Détection automatique de l'état de la connexion (`connectivity_plus`) et synchronisation bidirectionnelle en tâche de fond avec l'API backend MongoDB.
- **Authentification JWT :** Stockage sécurisé du jeton d'accès localement et injection automatique du header `Authorization: Bearer <token>` sur l'ensemble des requêtes sécurisées.

---

## Stack Technique Mobile

- **Framework :** Flutter (version stable, compatible Dart 3)
- **State Management :** Provider / ChangeNotifier
- **Base de données locale :** SQLite (`sqflite` + `path_provider`)
- **Réseau :** Package `http` avec interceptors pour les en-têtes JWT
- **Design :** Material Design 3 personnalisé

---

## Organisation du Code (`lib/`)

```text
lib/
├── models/             # Modèles de données (User, Trajet, DemandeReservation)
├── screens/            # Écrans de l'application
│   ├── auth/           # Écran de connexion (Login) et d'inscription
│   ├── passager/       # Recherche de trajets, carte, réservations
│   └── conducteur/     # Publication de trajets, gestion des demandes reçues
├── services/           # Logique métier et communication
│   ├── api_service.dart        # Client HTTP REST vers le backend Spring Boot
│   ├── auth_service.dart       # Gestion du cycle de vie du token JWT
│   ├── sync_service.dart       # Algorithme de synchronisation SQLite <-> MongoDB
│   └── database_helper.dart    # Initialisation et schémas des tables SQLite
└── main.dart           # Point d'entrée, configuration des routes et thèmes
```

---

## Lancement de l'Application

### 1. Prérequis
- Flutter SDK installé et configuré (`flutter doctor`)
- Un émulateur Android, un simulateur iOS ou un appareil physique connecté en débogage USB

### 2. Installation des Dépendances
```bash
flutter pub get
```

### 3. Configuration de l'Adresse de l'API
Par défaut, l'application pointe vers l'API locale :
- Émulateur Android : `http://10.0.2.2:8080`
- Appareil physique / Serveur distant : `http://10.6.0.7:8080` (serveur de la salle)

### 4. Exécuter l'Application
```bash
# Lancement en mode debug
flutter run
```

### 5. Lancer la Suite de Tests Mobile
```bash
flutter test
```
