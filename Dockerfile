# Build stage
FROM eclipse-temurin:21.0.2_13-jdk-jammy AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN apt-get update && apt-get install -y maven
RUN mvn clean package -DskipTests

# Run stage
FROM eclipse-temurin:21.0.2_13-jre-jammy
WORKDIR /app

# Create a non-root user
RUN useradd -r -u 1001 -g root springuser
USER springuser

COPY --from=build /app/target/*.jar app.jar

# Add build arguments for version tracking
ARG GITHUB_SHA
ARG GITHUB_REF
ENV GIT_SHA=${GITHUB_SHA}
ENV GIT_REF=${GITHUB_REF}

# Add metadata labels
LABEL org.opencontainers.image.source="https://github.com/vinaybalamuru/boot-k8s-sample-deploy"
LABEL org.opencontainers.image.description="Spring Boot Application"
LABEL org.opencontainers.image.licenses="MIT"

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"] 