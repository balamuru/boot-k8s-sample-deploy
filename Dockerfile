# Build stage
FROM --platform=$BUILDPLATFORM maven:3.9.9-eclipse-temurin-21 AS BUILD
WORKDIR /usr/src/app
COPY . .
RUN mvn --batch-mode -f pom.xml clean package

# Runtime stage
FROM --platform=$TARGETPLATFORM eclipse-temurin:21-jre
ENV PORT 8080
EXPOSE 8080
COPY --from=BUILD /usr/src/app/target /opt/target
WORKDIR /opt/target
CMD ["/bin/bash", "-c", "find -type f -name '*-SNAPSHOT.jar' | xargs java -jar"]