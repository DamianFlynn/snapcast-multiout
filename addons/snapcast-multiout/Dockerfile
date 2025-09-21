
# Use the base image specified in build.yaml
ARG BUILD_FROM
FROM $BUILD_FROM

# Set build environment for faster builds
ENV MAKEFLAGS="-j2"
ENV CMAKE_BUILD_PARALLEL_LEVEL=2

# Install essential packages in stages to avoid hanging
RUN apk update && apk add --no-cache \
    bash jq alsa-utils alsa-plugins coreutils usbutils

# Install build dependencies
RUN apk add --no-cache \
    build-base cmake git boost-dev libvorbis-dev libogg-dev \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev

# Install runtime dependencies  
RUN apk add --no-cache \
    libvorbis libogg alsa-lib avahi soxr flac opus expat openssl boost1.82-libs
# Build snapcast with simplified options
RUN git clone --recursive --depth=1 https://github.com/badaix/snapcast.git /snapcast \
    && sed -i '1i#include <sys/types.h>' /snapcast/common/utils/file_utils.hpp \
    && cd /snapcast \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF .. \
    && make -j2 snapserver snapclient \
    && make install \
    && cd / \
    && rm -rf /snapcast

# Clean up build dependencies to reduce image size
RUN apk del build-base cmake git boost-dev libvorbis-dev libogg-dev \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev

COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf
RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]
