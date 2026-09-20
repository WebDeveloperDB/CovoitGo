# Covoit'Go - API Backend

Covoit'Go est une plateforme de covoiturage. Ce dépôt contient le backend de l'application développé avec Java, Spring Boot et MongoDB.

## Prérequis

Pour exécuter ce projet localement, vous devez avoir installé :
- [Docker](https://www.docker.com/get-started) et [Docker Compose](https://docs.docker.com/compose/install/)
- (Optionnel) Java 17+ et Maven si vous souhaitez exécuter le projet sans Docker

## Clonage du projet

```bash
git clone https://git.uha4point0.fr/UHA40/fil-rouge-2026/4.0.3/covoitgo.git
cd covoitgo
```

## Variables d'environnement

Avant de démarrer le projet, vous devez configurer vos variables d'environnement. Des fichiers d'exemple sont fournis. 
Pour l'environnement de développement :

```bash
# Créez le fichier .env.dev à partir de l'exemple
cp .env.exemple.dev .env.dev
```

**Valeurs à renseigner dans `.env.dev` :**
- `SPRING_PROFILES_ACTIVE` : Profil Spring Boot (ex: `dev`)
- `API_PORT` : Port sur lequel l'API sera accessible (ex: `8080`)
- `MONGO_PORT` : Port sur lequel MongoDB sera accessible (ex: `27017`)
- `MONGODB_URI` : URI de connexion à la base de données. En développement Docker, utilisez `mongodb://mongodb:${MONGO_PORT}/covoitgo_dev`.

Vous pouvez faire de même pour les environnements de test (`.env.test`) et de production (`.env.prod`).

## Commandes Docker et Lancement du Backend

Le projet utilise Docker Compose pour orchestrer l'API et la base de données MongoDB.

**Lancer l'environnement de développement :**
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```
L'API sera disponible sur `http://localhost:${API_PORT}` (par défaut 8080).
L'interface de documentation Swagger est accessible sur `http://localhost:8080/swagger-ui/index.html`.

**Lancer les tests :**
```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml up --build --abort-on-container-exit
```

**Arrêter les conteneurs :**
```bash
docker-compose down
```

## Contrôles qualité et Tests

- **API de santé (Health Check)** : Vérifiez que l'API est correctement démarrée en appelant `http://localhost:8080/api/health` (doit retourner un statut `UP`).
- **Tests Unitaires** : Exécutables via Maven dans le conteneur ou localement avec `./mvnw test`.
- La base de données de test utilise un montage en mémoire (tmpfs) pour accélérer l'exécution et ne pas polluer l'environnement de développement.
