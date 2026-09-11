# ─── Stage 1: Build ───────────────────────────────────────────────────────────
# Use full JDK to compile and package the fat JAR
FROM --platform=linux/amd64 public.ecr.aws/docker/library/eclipse-temurin:17-jdk-alpine AS build

WORKDIR /workspace

# Copy Maven wrapper + pom first (layer-cache: only re-downloads deps when pom changes)
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download all dependencies (cached unless pom.xml changes)
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source and build (skip tests — they run in CI before this step)
COPY src src
RUN ./mvnw package -DskipTests -B

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
# Slim JRE-only image — ~100MB vs ~350MB for JDK
FROM --platform=linux/amd64 public.ecr.aws/docker/library/eclipse-temurin:17-jre-alpine AS runtime

WORKDIR /app

# Non-root user for security
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy the fat JAR from the build stage
COPY --from=build /workspace/target/*.jar app.jar

# Actuator health on 8081
EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
