# ─────────────────────────────────────────────────────────────────
# Dockerfile — Flutter Android APK builder
# Builds a release APK inside a Linux container.
# Usage:
#   docker build -t business-dashboard-apk .
#   docker run --rm -v "%cd%/output":/output business-dashboard-apk
# The APK will be copied to ./output/app-release.apk
# ─────────────────────────────────────────────────────────────────

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.44.1
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${PATH}:${JAVA_HOME}/bin:/opt/flutter/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"

# ── System dependencies ───────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# ── Android Command-Line Tools ────────────────────────────────────
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
         -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools && \
    mv /tmp/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm -rf /tmp/cmdline-tools.zip /tmp/cmdline-tools

# ── Accept Android licenses and install SDK components ───────────
RUN yes | sdkmanager --licenses && \
    sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0"

# ── Flutter SDK ───────────────────────────────────────────────────
RUN git clone https://github.com/flutter/flutter.git \
        --depth 1 --branch stable /opt/flutter && \
    flutter precache --android && \
    flutter config --no-analytics

# ── App source ───────────────────────────────────────────────────
WORKDIR /app
COPY . .

# ── Build release APK ─────────────────────────────────────────────
RUN flutter pub get && \
    flutter build apk --release

# ── Copy APK to /output on container run ─────────────────────────
CMD ["sh", "-c", "cp build/app/outputs/flutter-apk/app-release.apk /output/app-release.apk && echo 'APK copied to /output/app-release.apk'"]
