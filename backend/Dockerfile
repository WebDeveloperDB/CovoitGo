# Multi-stage Dockerfile pour CovoitGo Backend
# Étape 1 : Compilation et packaging avec JDK
FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn
RUN chmod +x mvnw

# Copie des sources Java et compilation du JAR
COPY src src
RUN ./mvnw --batch-mode clean package -DskipTests

# Étape 2 : Image d'exécution minimale avec JRE Alpine (AUCUN CODE SOURCE)
FROM eclipse-temurin:21-jre-alpine AS runtime

# Création d'un utilisateur non privilégié pour la sécurité (recommandation du guide)
RUN addgroup -S covoitgo && adduser -S covoitgo -G covoitgo

WORKDIR /app

# Copie exclusive du binaire exécutable .jar généré dans le stage build
COPY --from=build /workspace/target/*.jar app.jar
RUN chown -R covoitgo:covoitgo /app

# Exécution sous l'utilisateur non privilégié
USER covoitgo

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]