# Covoit'Go - Plateforme de Covoiturage Intelligente & Offline-First

Covoit'Go est une application mobile et backend de covoiturage solidaire développée dans le cadre du projet Fil Rouge (UHA 4.0 - Promo 2026).
Elle permet aux conducteurs de proposer des trajets et aux passagers de rechercher, réserver et gérer leurs déplacements en temps réel, avec une prise en charge complète du **mode hors-ligne (Offline-First)** et un **déploiement continu automatisé (CI/CD)**.

---

## Fonctionnalités Principales

- **Authentification & Sécurité Stateless :** Connexion et inscription sécurisées avec JSON Web Tokens (JWT) signés en HMAC-SHA256 et hachage des mots de passe avec BCrypt.
- **Rôles Utilisateurs :** Espaces et parcours dédiés pour les **Passagers** (recherche par géolocalisation, réservation) et les **Conducteurs** (publication de trajets, acceptation/refus de demandes).
- **Calcul Géographique & Recherche par Rayon :** Algorithme de calcul de distance basé sur la formule Haversine pour trouver les trajets les plus proches.
- **Architecture Offline-First (Mode Hors-Ligne) :** Les passagers peuvent consulter et créer des demandes de réservation sans connexion Internet grâce à un stockage local SQLite.
- **Synchronisation Automatique Bidirectionnelle :** Dès le retour de la connexion, un service d'arrière-plan synchronise les données locales avec l'API centrale MongoDB et résout les conflits d'horodatage.
- **Pipeline DevOps & CI/CD Complète :** Intégration et déploiement continus via GitLab CI/CD (Build, Tests automatisés, Conteneurisation Docker Multi-stage sans sources et Déploiement continu par flux SSH).

---

## Architecture Globale & Stack Technique

```text
┌─────────────────────────────────┐
│     Application Mobile Flutter  │
│  (Dart 3, Provider, SQLite)     │
└────────────────┬────────────────┘
                 │ HTTP / REST + Bearer JWT
                 ▼
┌─────────────────────────────────┐
│     Backend API Spring Boot 3   │
│  (Java 21, Spring Security)     │
└────────────────┬────────────────┘
                 │ Protocole MongoDB
                 ▼
┌─────────────────────────────────┐
│      Base de Données NoSQL      │
│         (MongoDB 7.0)           │
└─────────────────────────────────┘
```

| Composant | Technologies | Description |
|---|---|---|
| **Frontend Mobile** | Flutter, Dart, SQLite (sqflite), Provider | Application cross-platform iOS/Android avec gestion d'état et persistance locale |
| **Backend API** | Java 21, Spring Boot 3, Spring Security, Maven | API RESTful modulaire, validation métier et sécurisation par filtres JWT |
| **Base de Données** | MongoDB 7.0 (NoSQL) | Stockage flexible des trajets, réservations et profils utilisateurs |
| **DevOps & CI/CD** | GitLab CI, Docker, Docker Compose, SSH Ed25519 | Automatisation du cycle de vie logiciel (Build, Test, Package, Deploy) |

---

## Structure du Projet

```text
CovoitGo/
├── backend/                  # Code source de l'API Spring Boot
│   ├── src/main/java/        # Contrôleurs REST, Services, Modèles, Sécurité JWT
│   ├── src/test/java/        # 34 tests d'intégration automatisés
│   ├── Dockerfile            # Multi-stage build de production
│   └── pom.xml               # Gestionnaire de dépendances Maven
├── mobile/                   # Application mobile Flutter
│   ├── lib/                  # Écrans (Conducteur/Passager), Modèles, Services
│   │   ├── services/         # AuthService, ApiService, SyncService, DatabaseHelper (SQLite)
│   │   └── screens/          # Écrans de Login, Recherche, Trajets, Demandes
│   └── test/                 # Tests unitaires et de widgets Flutter
├── .gitlab-ci.yml            # Pipeline CI/CD en 4 stages (BUILD, TEST, PACKAGE, DEPLOY)
├── compose.prod.yaml         # Configuration Docker Compose de production
└── docker-compose.dev.yml    # Environnement Docker local pour le développement
```

---

## Démarrage Rapide

### 1. Prérequis
- [Docker](https://www.docker.com/) & [Docker Compose](https://docs.docker.com/compose/)
- [Java 21](https://adoptium.net/) & Maven (si exécution locale du backend)
- [Flutter SDK (stable)](https://flutter.dev/) (pour l'application mobile)

### 2. Cloner le Dépôt
```bash
git clone https://git.uha4point0.fr/UHA40/fil-rouge-2026/4.0.3/covoitgo.git
cd covoitgo
```

### 3. Lancer le Backend & MongoDB (Docker)
```bash
# Configuration des variables d'environnement de développement
cp .env.exemple.dev .env.dev

# Lancement des conteneurs (API + Base de données MongoDB)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```
- L'API est disponible sur : `http://localhost:8080`
- Sonde de santé (Healthcheck) : `http://localhost:8080/health` (doit renvoyer `{"status":"UP", ...}`)
- Documentation interactive Swagger : `http://localhost:8080/swagger-ui/index.html`

### 4. Lancer l'Application Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

---

## Tests Automatisés & Contrôle Qualité

Le projet intègre une couverture de tests automatisés rigoureuse :
- **Backend (34 tests d'intégration sans mock) :**
  ```bash
  cd backend
  ./mvnw test
  ```
  Valide la formule Haversine, les flux de réservation, les règles de concurrence et les refus HTTP 401/403 de Spring Security.
- **Mobile (Tests unitaires & Widgets) :**
  ```bash
  cd mobile
  flutter test
  ```
- **Pipeline CI/CD :** À chaque `git push`, le GitLab Runner valide automatiquement la compilation, l'exécution des tests, la fabrication de l'image Docker sans code source et le déploiement continu sur le serveur distant.

---

## Auteur
- **Bajram Dzaferi** - Étudiant Développeur d'Applications (UHA 4.0 - Promo 2026)
