################################################################################
# Default Variables
################################################################################

# TARGET="x86_64-multilib-linux-musl"

# BUILD_UID="1000"
# BUILD_GID="1000"

# DEBIAN_MIRROR
# DEBIAN_SECURITY

################################################################################
# Crosstool-NG Stage
################################################################################

FROM debian:stable-slim AS crosstool-ng

ENV CTNG_VERSION="1.24.0"

ARG DEBIAN_MIRROR
ARG DEBIAN_SECURITY

RUN if [ -n "${DEBIAN_MIRROR}" ]; then \
      sed -i -e '/.* stable .*/d' /etc/apt/sources.list; \
      sed -i -e '/.* stable-updates .*/d' /etc/apt/sources.list; \
      echo "deb ${DEBIAN_MIRROR} stable         main contrib non-free" >> /etc/apt/sources.list; \
      echo "deb ${DEBIAN_MIRROR} stable-updates main contrib non-free" >> /etc/apt/sources.list; \
    fi

RUN if [ -n "${DEBIAN_SECURITY}" ]; then \
      sed -i -e '/.* stable\/updates .*/d' /etc/apt/sources.list; \
      echo "deb ${DEBIAN_SECURITY} stable/updates main contrib non-free" >> /etc/apt/sources.list; \
    fi

RUN apt-get update \
 && apt-get install -yqq --no-install-recommends \
      autoconf \
      automake \
      bison \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      flex \
      gawk \
      gettext \
      help2man \
      libncurses5-dev \
      libtool-bin \
      texinfo \
      unzip \
      xz-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL --retry 10 --retry-connrefused -o crosstool-ng-${CTNG_VERSION}.tar.xz \
      http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-${CTNG_VERSION}.tar.xz

RUN tar -xf crosstool-ng-${CTNG_VERSION}.tar.xz -C /usr/src && rm crosstool-ng-${CTNG_VERSION}.tar.xz

WORKDIR /usr/src/crosstool-ng-${CTNG_VERSION}

RUN ./bootstrap
RUN ./configure --prefix=/opt/crosstool-ng
RUN make install

################################################################################
# Toolchain Stage
################################################################################

FROM debian:stable-slim AS toolchain
COPY --from=crosstool-ng /opt/crosstool-ng /opt/crosstool-ng
RUN ln -s /opt/crosstool-ng/bin/ct-ng /usr/local/bin/ct-ng
RUN ln -s /opt/crosstool-ng/share/bash-completion/completions/ct-ng \
      /usr/share/bash-completion/completions/ct-ng

ARG TARGET="x86_64-multilib-linux-musl"

ARG BUILD_UID="1000"
ARG BUILD_GID="1000"

ARG DEBIAN_MIRROR
ARG DEBIAN_SECURITY

RUN if [ -n "${DEBIAN_MIRROR}" ]; then \
      sed -i -e '/.* stable .*/d' /etc/apt/sources.list; \
      sed -i -e '/.* stable-updates .*/d' /etc/apt/sources.list; \
      echo "deb ${DEBIAN_MIRROR} stable         main contrib non-free" >> /etc/apt/sources.list; \
      echo "deb ${DEBIAN_MIRROR} stable-updates main contrib non-free" >> /etc/apt/sources.list; \
    fi

RUN if [ -n "${DEBIAN_SECURITY}" ]; then \
      sed -i -e '/.* stable/updates .*/d' /etc/apt/sources.list; \
      echo "deb ${DEBIAN_SECURITY} stable/updates main contrib non-free" >> /etc/apt/sources.list; \
    fi

RUN apt-get update \
 && apt-get install -yqq --no-install-recommends \
      autoconf \
      automake \
      bash-completion \
      bison \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      flex \
      gawk \
      gettext \
      help2man \
      libncurses5-dev \
      libtool-bin \
      texinfo \
      unzip \
      xz-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY targets /targets
COPY .tarballs /cross/src

RUN groupadd -g $BUILD_GID cross
RUN useradd -d /cross -g $BUILD_GID -u $BUILD_UID -s /bin/bash cross
RUN chown -R cross:cross /cross
USER cross
WORKDIR /cross

RUN DEFCONFIG=/targets/${TARGET}/defconfig ct-ng defconfig
RUN ct-ng source
RUN ct-ng build

################################################################################
# Distribution Stage
################################################################################

FROM debian:stable-slim AS distribution
ARG TARGET="x86_64-multilib-linux-musl"
COPY --from=toolchain --chown=0:0 /cross/x-tools/${TARGET} /opt/${TARGET}
RUN echo "export PATH=/opt/${TARGET}/bin:$PATH" > /etc/profile.d/${TARGET}.sh
ENV PATH="/opt/${TARGET}/bin:$PATH"
