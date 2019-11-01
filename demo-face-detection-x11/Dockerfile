FROM alpine AS qemu

# Download QEMU, see https://github.com/docker/hub-feedback/issues/1261
ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-aarch64.tar.gz
RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1

FROM registry.gitlab.com/likeablob/openvino-docker:devel-runtime-arm64v8 as DEV

# Add QEMU
COPY --from=qemu qemu-aarch64-static /usr/bin

RUN apt-get update && apt-get install --no-install-recommends -y \
  git \
  ca-certificates \
  gcc \
  make \
  python3-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone https://github.com/doceme/py-spidev.git py-spidev \
  && cd py-spidev \
  && python3 setup.py install

