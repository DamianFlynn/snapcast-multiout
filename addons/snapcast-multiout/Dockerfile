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

# Build snapcast with timeout protection and smaller parallel jobs
RUN timeout 900 git clone --recursive --depth=1 https://github.com/badaix/snapcast.git /snapcast || \
    (echo "Git clone timed out, trying again..." && git clone --depth=1 https://github.com/badaix/snapcast.git /snapcast)

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
RUN if [ -f "/snapcast/server/snapweb/package.json" ]; then \
        echo "Building snapweb interface..." && \
        cd /snapcast/server/snapweb && \
        npm install && npm run build; \
    elif [ -f "/snapcast/snapweb/package.json" ]; then \
        echo "Building snapweb interface..." && \
        cd /snapcast/snapweb && \
        npm install && npm run build; \
    else \
        echo "No package.json found for web interface"; \
    fi

# Install snapweb files with better detection
RUN mkdir -p /usr/share/snapserver/snapweb && \
    if [ -d "/snapcast/server/snapweb" ]; then \
        echo "Found snapweb in /snapcast/server/snapweb" && \
        cp -r /snapcast/server/snapweb/* /usr/share/snapserver/snapweb/; \
    elif [ -d "/snapcast/snapweb" ]; then \
        echo "Found snapweb in /snapcast/snapweb" && \
        cp -r /snapcast/snapweb/* /usr/share/snapserver/snapweb/; \
    elif [ -d "/snapcast/client/snapweb" ]; then \
        echo "Found snapweb in /snapcast/client/snapweb" && \
        cp -r /snapcast/client/snapweb/* /usr/share/snapserver/snapweb/; \
    else \
        echo "Warning: snapweb files not found in snapcast source, creating minimal index.html"; \
        echo '<html><head><title>Snapcast Server</title></head><body><h1>Snapcast Server</h1><p>Web interface files not available in this build</p><p>Server is running on port 1780</p></body></html>' > /usr/share/snapserver/snapweb/index.html; \
    fi

# Clean up
WORKDIR /
RUN rm -rf /snapcast
RUN apk del build-base cmake git boost-dev libvorbis-dev libogg-dev \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev \
    nodejs npm

COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf
RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]