# Use the base image specified in build.yaml
ARG BUILD_FROM
FROM $BUILD_FROM

# Use the base image specified in build.yaml
ARG BUILD_FROM
FROM $BUILD_FROM

# Install essential packages first
RUN apk update && apk add --no-cache \
    bash jq alsa-utils alsa-plugins coreutils usbutils

# Install build dependencies in smaller batches to prevent timeouts
RUN apk add --no-cache build-base cmake git
RUN apk add --no-cache boost-dev libvorbis-dev libogg-dev
RUN apk add --no-cache alsa-lib-dev avahi-dev soxr-dev 
RUN apk add --no-cache flac-dev opus-dev expat-dev openssl-dev

# Install runtime dependencies  
RUN apk add --no-cache \
    libvorbis libogg alsa-lib avahi soxr flac opus expat openssl boost1.82-libs

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

# Clean up
WORKDIR /
RUN rm -rf /snapcast
RUN apk del build-base cmake git boost-dev libvorbis-dev libogg-dev \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev

COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf
RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]