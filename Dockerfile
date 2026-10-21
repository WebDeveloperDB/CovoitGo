# Multi-stage Dockerfile pour CovoitGo Backend
# Étape 1 : Compilation et packaging avec JDK
FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace
COPY backend/ .
RUN chmod +x mvnw && ./mvnw --batch-mode clean package -DskipTests

# Étape 2 : Image d'exécution minimale avec JRE (AUCUN CODE SOURCE)
FROM eclipse-temurin:21-jre AS runtime

WORKDIR /app
COPY --from=build /workspace/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
