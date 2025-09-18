
# Use Alpine as the base image
FROM alpine:3.19

# Install build and runtime dependencies
RUN apk add --no-cache \
    bash jq alsa-utils alsa-plugins \
    build-base cmake git boost-dev libvorbis-dev libogg-dev libpng-dev \
    python3 py3-pip curl \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev \
    && apk add --no-cache --virtual .runtime-deps \
    libvorbis libogg alsa-lib avahi soxr flac opus expat openssl boost1.82-libs
RUN git clone --recursive https://github.com/badaix/snapcast.git /snapcast \
    && sed -i '1i#include <sys/types.h>' /snapcast/common/utils/file_utils.hpp \
    && cd /snapcast \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j2 \
    && make install

# Clean up build dependencies and source (keep runtime libraries)
RUN rm -rf /snapcast && apk del build-base cmake git boost-dev libvorbis-dev libogg-dev libpng-dev python3 py3-pip curl \
    alsa-lib-dev avahi-dev soxr-dev flac-dev opus-dev expat-dev openssl-dev

COPY run.sh /run.sh
COPY gen_snapserver.sh /gen_snapserver.sh
COPY asound.conf /etc/asound.conf
RUN chmod +x /run.sh /gen_snapserver.sh

CMD ["/run.sh"]
