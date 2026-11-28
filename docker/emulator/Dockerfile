FROM ubuntu:24.04 AS sdk

ARG DEBIAN_FRONTEND=noninteractive
ARG ANDROID_SDK_TOOLS_VERSION=16111833
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV JAVA_HOME=/opt/java
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl unzip && \
  rm -rf /var/lib/apt/lists/*

RUN curl -fsSL 'https://github.com/adoptium/temurin27-binaries/releases/download/jdk-27.0.1.1%2B4/OpenJDK27U-jdk_x64_linux_hotspot_27.0.1.1_4.tar.gz' \
    -o /tmp/java.tar.gz && \
  echo '005e57ee860978acfeeff1be2b30f770664fe2b941e9b803c61c76992086d107  /tmp/java.tar.gz' | sha256sum -c - && \
  mkdir -p "$JAVA_HOME" && \
  tar -xzf /tmp/java.tar.gz -C "$JAVA_HOME" --strip-components=1 && \
  rm /tmp/java.tar.gz

RUN mkdir -p "$ANDROID_HOME/cmdline-tools" && \
  curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" \
    -o /tmp/commandlinetools.zip && \
  unzip -q /tmp/commandlinetools.zip -d /tmp/commandlinetools && \
  mv /tmp/commandlinetools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest" && \
  yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null && \
  "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    'emulator' 'platform-tools' 'system-images;android-36;default;x86_64'

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV ANDROID_SDK_ROOT=/opt/android-sdk-linux
ENV ANDROID_AVD_HOME=/var/lib/memora-emulator/avd
ENV PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates libasound2t64 libglib2.0-0t64 libnss3 libpulse0 libvulkan1 \
  libx11-6 libxcb1 libxcomposite1 libxcursor1 libxi6 libxkbcommon0 \
  libxrandr2 libxtst6 socat && \
  rm -rf /var/lib/apt/lists/*

COPY --from=sdk /opt/android-sdk-linux/emulator /opt/android-sdk-linux/emulator
COPY --from=sdk /opt/android-sdk-linux/platform-tools /opt/android-sdk-linux/platform-tools
COPY --from=sdk /opt/android-sdk-linux/system-images /opt/android-sdk-linux/system-images
COPY config.ini /opt/memora-emulator/config.ini
COPY start.sh /usr/local/bin/start-emulator

ENTRYPOINT ["bash", "/usr/local/bin/start-emulator"]
