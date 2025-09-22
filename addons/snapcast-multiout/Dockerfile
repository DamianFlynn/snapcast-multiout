# Use the base image specified in build.yaml
ARG BUILD_FROM
FROM $BUILD_FROM

# Install essential packages first
RUN apk update && apk add --no-cache \
    bash jq alsa-utils alsa-plugins alsa-plugins-pulse coreutils usbutils

# Install build dependencies in smaller batches to prevent timeouts
RUN apk add --no-cache build-base cmake git
RUN apk add --no-cache boost-dev libvorbis-dev libogg-dev
RUN apk add --no-cache alsa-lib-dev avahi-dev soxr-dev 
RUN apk add --no-cache flac-dev opus-dev expat-dev openssl-dev

# Add Node.js for potential web interface building
RUN apk add --no-cache nodejs npm

# Install runtime dependencies  
RUN apk add --no-cache \
    libvorbis libogg alsa-lib avahi soxr flac opus expat openssl boost1.82-libs \
    pulseaudio-alsa

# Build snapcast from source
RUN timeout 900 git clone --recursive --depth=1 https://github.com/badaix/snapcast.git /snapcast || \
    (echo "Git clone timed out, trying again..." && git clone --depth=1 https://github.com/badaix/snapcast.git /snapcast)

# Clone snapweb separately 
RUN git clone --depth=1 https://github.com/badaix/snapweb.git /snapweb

WORKDIR /snapcast
RUN sed -i '1i#include <sys/types.h>' /snapcast/common/utils/file_utils.hpp

# Build with conservative settings to prevent hanging
RUN mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF .. && \
    make -j1 snapserver snapclient && \
    make install

# Debug: Check what's actually available in the snapcast directory
RUN echo "=== Checking snapcast directory structure ===" && \
    find /snapcast -name "*web*" -type d 2>/dev/null || echo "No web directories found" && \
    find /snapcast -name "*.html" -o -name "*.js" -o -name "*.css" 2>/dev/null | head -10 || echo "No web files found" && \
    ls -la /snapcast/ && \
    echo "=== End directory check ==="

# Try to build web interface if package.json exists
RUN echo "Building snapweb interface..." && \
    cd /snapweb && \
    npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    (npm install --prefer-offline || npm install || echo "npm install failed, will use source files") && \
    (npm run build || echo "npm build failed, will use source files") && \
    echo "Snapweb build completed"

# Install snapweb files and patch for ingress compatibility
RUN mkdir -p /usr/share/snapserver/snapweb && \
    if [ -d "/snapweb/dist" ]; then \
        echo "Installing built snapweb from /snapweb/dist" && \
        cp -r /snapweb/dist/* /usr/share/snapserver/snapweb/; \
    elif [ -d "/snapweb/build" ]; then \
        echo "Installing built snapweb from /snapweb/build" && \
        cp -r /snapweb/build/* /usr/share/snapserver/snapweb/; \
    elif [ -d "/snapweb" ]; then \
        echo "Installing snapweb source files" && \
        cp -r /snapweb/* /usr/share/snapserver/snapweb/; \
    else \
        echo "No snapweb found, using custom interface"; \
    fi && \
    echo "Patching snapweb for Home Assistant ingress compatibility" && \
    find /usr/share/snapserver/snapweb -name "*.html" -exec sed -i 's|</head>|<script>!function(){if(window.location.pathname.includes("/hassio/ingress/")){window.addEventListener("load",function(){setTimeout(function(){if(window.config){const u=window.location.pathname.replace(/\/$/,"");window.config.baseUrl=(window.location.protocol==="https:"?"wss://":"ws://")+window.location.host+u;console.log("Set snapweb baseUrl for ingress:",window.config.baseUrl)}},500)})}}();</script></head>|' {} \;

# Clean up
WORKDIR /
RUN rm -rf /snapcast /snapweb
RUN apk del build-base cmake git boost-dev libvorbis-dev libogg-dev \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev \
    nodejs npm

COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf
RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]