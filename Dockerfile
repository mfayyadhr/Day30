    # Stage 1: Build the Spring Boot application
    FROM maven:3.9.4-eclipse-temurin-21 AS builder
    WORKDIR /app
    COPY pom.xml .
    COPY src ./src
    RUN mvn clean package -DskipTests

    # Stage 2: Create the final runtime image
    FROM bitnami/java:21
    WORKDIR /app
    COPY --from=builder /app/target/*.jar app.jar
    EXPOSE 8080
    CMD ["java", "-jar", "app.jar"]
