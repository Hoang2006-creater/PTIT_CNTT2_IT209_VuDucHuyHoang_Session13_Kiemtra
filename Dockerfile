# ==========================================
# Root Dockerfile for Campus Hub Backend
# Allows building directly from root repository:
#   docker build -t campus-hub-backend .
# ==========================================
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app

# Copy gradle wrapper and backend build configuration
COPY backend/gradlew backend/gradlew.bat backend/settings.gradle backend/build.gradle ./
COPY backend/gradle ./gradle

# Fix line endings (CRLF -> LF) and grant execute permissions
RUN sed -i 's/\r$//' ./gradlew && chmod +x ./gradlew

# Cache dependencies
RUN ./gradlew dependencies --no-daemon || true

# Copy backend source code and build jar
COPY backend/src ./src
RUN ./gradlew bootJar --no-daemon -x test

# ==========================================
# Stage 2: Minimal Runtime using JRE 21
# ==========================================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create a non-root group and user for security
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Copy jar from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
