# Stage 1: compile. Needs the JDK and the source tree.
FROM eclipse-temurin:25.0.4_7-jdk-noble AS build
WORKDIR /build

# Dependency descriptors first: this layer is cached and only invalidated
# when the build definition itself changes, not on every source edit.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw -q dependency:go-offline

COPY src/ src/
RUN ./mvnw -q package -DskipTests

# Stage 2: run. No compiler, no source, no build tool.
FROM eclipse-temurin:25.0.4_7-jre-noble
WORKDIR /app

# Unprivileged account. A process that escapes the application still holds
# no rights inside the container.
RUN useradd --system --uid 10001 --no-create-home appuser

COPY --from=build /build/target/*.jar app.jar
USER appuser

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
