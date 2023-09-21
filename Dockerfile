# SDRPLAY RSP API build container
FROM debian:bullseye-slim as build_rsp_api

# need some work to build for arm architectures
ARG SDRPLAY_API=https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run
ARG BUILD_DIR=/build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update \
    && apt-get -y --no-install-recommends install \
        curl \
        ca-certificates

WORKDIR ${BUILD_DIR}
RUN curl ${SDRPLAY_API} -o SDRplay_RSP_API.run \
    && chmod +x SDRplay_RSP_API.run \
    && ./SDRplay_RSP_API.run --tar -xvf \
    && cp x86_64/libsdrplay_api.so.3.07 /usr/lib/libsdrplay_api.so \
    && cp x86_64/libsdrplay_api.so.3.07 /usr/lib/libsdrplay_api.so.3.07 \
    && cp x86_64/sdrplay_apiService /usr/bin/sdrplay_apiService \
    && cp inc/* /usr/include \
    && chmod 644 /usr/lib/libsdrplay_api.so /usr/lib/libsdrplay_api.so.3.07 /usr/include/* \
    && chmod 755 /usr/bin/sdrplay_apiService

# codecserver for soft MBE build container
FROM debian:bullseye-slim as build_codecserver_softmbe

ARG BUILD_DIR=/build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gpg \
        wget \
        ca-certificates \
        git \
        debhelper \
        build-essential \
        cmake \
        libprotobuf-dev \
        protobuf-compiler \
    && wget -q -O - https://repo.openwebrx.de/debian/key.gpg.txt | gpg --dearmor -o /usr/share/keyrings/openwebrx.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/openwebrx.gpg] https://repo.openwebrx.de/debian/ bullseye main" > /etc/apt/sources.list.d/openwebrx.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libcodecserver-dev

WORKDIR ${BUILD_DIR}
RUN git clone https://github.com/szechyjs/mbelib.git \
    && cd mbelib \
    && dpkg-buildpackage \
    && cd .. \
    && dpkg -i libmbe*.deb

WORKDIR ${BUILD_DIR}
RUN git clone https://github.com/knatterfunker/codecserver-softmbe.git \
    && cd codecserver-softmbe \
    && dpkg-buildpackage

# acarsdec build container
FROM debian:bullseye-slim as build_acarsdec

ARG BUILD_DIR=/build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        git \
        build-essential \
        cmake \
        libxml2-dev \
        libsndfile1-dev \
        libjansson-dev

RUN git clone https://github.com/szpajder/libacars \
    && cd libacars \
    && git checkout unstable \
    && mkdir build && cd build \
    && cmake .. && make && make install \
    && ldconfig

RUN git clone https://github.com/jketterl/acarsdec \
    && cd acarsdec \
    && git checkout add_stdin \
    && mkdir build && cd build \
    && cmake .. && make && make install

RUN ldd $(which acarsdec) | cut -d" " -f3 | xargs tar --dereference -cf /tmp/libs.tar

# dream build container
FROM debian:bullseye-slim as build_dream

ARG BUILD_DIR=/build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        build-essential \
        qt5-qmake libpulse0 libfaad2 libopus0 libpulse-dev libfaad-dev libopus-dev libfftw3-dev

WORKDIR ${BUILD_DIR}
RUN wget -q -O - https://downloads.sourceforge.net/project/drm/dream/2.1.1/dream-2.1.1-svn808.tar.gz | tar xvfz - \
    && cd dream \
    && qmake -qt=qt5 CONFIG+=console \
    && make && make install

RUN ldd $(which dream) | cut -d" " -f3 | xargs tar --dereference -cf /tmp/libs.tar

# freedv_rx build container
FROM debian:bullseye-slim as build_freedv

ARG BUILD_DIR=/build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        git \
        build-essential \
        cmake

RUN git clone https://github.com/drowe67/codec2.git \
    && cd codec2 \
    && mkdir build && cd build \
    && cmake .. && make && make install && install -m 0755 src/freedv_rx /usr/local/bin

RUN ldd $(which freedv_rx) | cut -d" " -f3 | xargs tar --dereference -cf /tmp/libs.tar

# openwebrxplus final container
FROM debian:bullseye-slim as build_owrx

ARG OPENWEBRX_ADMIN_USER=admin
ARG OPENWEBRX_ADMIN_PASSWORD=admin
ENV DEBIAN_FRONTEND=noninteractive

# need some utilities
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gpg \
        wget \
        ca-certificates \
        tini

# install owrx and some decoders from the debian and openwebrx/plus repositories
RUN wget -q -O - https://luarvique.github.io/ppa/openwebrx-plus.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/debian ./" > /etc/apt/sources.list.d/openwebrx-plus.list \
    && wget -q -O - https://repo.openwebrx.de/debian/key.gpg.txt | gpg --dearmor -o /usr/share/keyrings/openwebrx.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/openwebrx.gpg] https://repo.openwebrx.de/debian/ bullseye main" > /etc/apt/sources.list.d/openwebrx.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        openwebrx \
        soapysdr-module-sdrplay3 \
        direwolf \
        aprs-symbols \
        python3-digiham \
        multimon-ng \
        rtl-433 \
        dumphfdl \
        dumpvdl2 \
        dump1090-fa \
        msk144decoder \
        m17-demod \
        codecserver \
        wsjtx \
        js8call \
        python3-js8py \
        nmux \
        libfaad-dev \
        imagemagick

# install the container entrypoint
COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh

# install SDRPLAY RSP API
COPY --from=build_rsp_api /usr/lib/libsdrplay_api.so /usr/lib/libsdrplay_api.so
COPY --from=build_rsp_api /usr/bin/sdrplay_apiService /usr/bin/sdrplay_apiService

# install codecserver for soft MBE
COPY --from=build_codecserver_softmbe /build/*.deb  /tmp/packages/
WORKDIR /tmp/packages
RUN dpkg -i *.deb && rm -r /tmp/packages
RUN echo '[device:softmbe]\ndriver=softmbe\n' >>/etc/codecserver/codecserver.conf

# install acarsdec
COPY --from=build_acarsdec /usr/local/bin/acarsdec /usr/local/bin/acarsdec
COPY --from=build_acarsdec /tmp/libs.tar /tmp/libs.tar
WORKDIR /
RUN tar -xf /tmp/libs.tar && rm /tmp/libs.tar

# install dream
COPY --from=build_dream /usr/bin/dream /usr/bin/dream
COPY --from=build_dream /tmp/libs.tar /tmp/libs.tar
WORKDIR /
RUN tar -xf /tmp/libs.tar && rm /tmp/libs.tar

# install freedv_rx
COPY --from=build_freedv /usr/local/bin/freedv_rx /usr/local/bin/freedv_rx
COPY --from=build_freedv /tmp/libs.tar /tmp/libs.tar
WORKDIR /
RUN tar -xf /tmp/libs.tar && rm /tmp/libs.tar

# config libraries and clean
RUN ldconfig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "/usr/bin/tini", "--", "/etc/entrypoint.sh" ]

VOLUME /var/lib/openwebrx

EXPOSE 8073/tcp
