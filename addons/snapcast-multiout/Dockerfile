# Multi-stage build for better caching and smaller final image
# Stage 1: Build snapcast from source
FROM docker.io/library/alpine:3.19 AS builder

# Install build dependencies in a single layer
RUN apk update && apk add --no-cache \
    build-base cmake git \
    boost-dev libvorbis-dev libogg-dev \
    alsa-lib-dev avahi-dev soxr-dev \
    flac-dev opus-dev expat-dev openssl-dev \
    nodejs npm

# Clone source code (this layer can be cached)
RUN git clone --recursive --depth=1 https://github.com/badaix/snapcast.git /snapcast && \
    git clone --depth=1 https://github.com/badaix/snapweb.git /snapweb

# Build snapcast (this is the expensive step that we want to cache)
WORKDIR /snapcast
RUN sed -i '1i#include <sys/types.h>' /snapcast/common/utils/file_utils.hpp && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF .. && \
    make -j$(nproc) snapserver snapclient && \
    make install

# Build snapweb
WORKDIR /snapweb
RUN npm install && \
    npm run build

# Stage 2: Runtime image
ARG BUILD_FROM=docker.io/library/alpine:3.19
FROM $BUILD_FROM

# Cache buster for Home Assistant rebuilds - change this value to force rebuild
ENV ADDON_VERSION="2025.09.23-2"
ENV BUILD_DATE="2025-09-23"

# Install only runtime dependencies
RUN apk update && apk add --no-cache \
    bash jq alsa-utils alsa-plugins alsa-plugins-pulse coreutils usbutils \
    libvorbis libogg alsa-lib avahi soxr flac opus expat openssl boost1.82-libs \
    pulseaudio-alsa

# Copy binaries from builder stage
COPY --from=builder /usr/local/bin/snapserver /usr/local/bin/snapclient /usr/local/bin/

# Install snapweb files
RUN mkdir -p /usr/share/snapserver/snapweb
COPY --from=builder /snapweb/dist/* /usr/share/snapserver/snapweb/

# Patch snapweb for Home Assistant ingress compatibility
RUN echo "Patching snapweb for Home Assistant ingress compatibility" && \
    find /usr/share/snapserver/snapweb -name "*.html" -exec sed -i 's|</head>|<script>!function(){if(window.location.pathname.includes("/hassio/ingress/")){window.addEventListener("load",function(){setTimeout(function(){if(window.config){const u=window.location.pathname.replace(/\/$/,"");window.config.baseUrl=(window.location.protocol==="https:"?"wss://":"ws://")+window.location.host+u;console.log("Set snapweb baseUrl for ingress:",window.config.baseUrl)}},500)})}}();</script></head>|' {} \;

# Copy addon files
COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf
RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]