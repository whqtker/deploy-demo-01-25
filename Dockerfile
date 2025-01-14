# 첫 번째 스테이지: 빌드 스테이지
FROM gradle:jdk21-graal-jammy AS builder

WORKDIR /app

# Gradle 캐시 레이어 최적화
COPY build.gradle settings.gradle ./
COPY gradle gradle
COPY gradlew .

# Gradle 래퍼 권한 설정 및 검증
RUN chmod +x gradlew && \
    ./gradlew --version

# 의존성 다운로드
COPY gradle gradle
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew dependencies --no-daemon

# 소스 코드 복사 및 빌드
COPY src src
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew build --no-daemon

# 두 번째 스테이지: 실행 스테이지
FROM ghcr.io/graalvm/jdk-community:21

WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/build/libs/*.jar app.jar

ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "app.jar"]