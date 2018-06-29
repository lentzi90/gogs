FROM arm64v8/alpine:3.6

ENV GOGS_CUSTOM /data/gogs
ENV QEMU_EXECVE 1

# For cross compile on dockerhub
################################

COPY ./docker/aarch64/qemu-aarch64-static /usr/bin/
COPY ./docker/aarch64/resin-xbuild /usr/bin/

RUN [ "/usr/bin/qemu-aarch64-static", "/bin/sh", "-c", "ln -s resin-xbuild /usr/bin/cross-build-start; ln -s resin-xbuild /usr/bin/cross-build-end; ln /bin/sh /bin/sh.real" ]

RUN [ "cross-build-start" ]

# Prepare the container
#######################

# Install system utils & Gogs runtime dependencies
ADD https://github.com/tianon/gosu/releases/download/1.9/gosu-arm64 /usr/sbin/gosu
RUN chmod +x /usr/sbin/gosu \
  && echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories \
  && apk --no-cache --no-progress add \
    bash \
    ca-certificates \
    curl \
    git \
    linux-pam \
    openssh \
    s6 \
    shadow \
    socat \
    tzdata

# Configure LibC Name Service
COPY docker/nsswitch.conf /etc/nsswitch.conf
COPY docker /app/gogs/docker
COPY templates /app/gogs/templates
COPY public /app/gogs/public

WORKDIR /app/gogs/build
COPY . .

RUN    ./docker/build-go.sh \
    && ./docker/build.sh \
    && ./docker/finalize.sh

# For cross compile on dockerhub
################################

RUN [ "cross-build-end" ]

# Configure Docker Container
############################
VOLUME ["/data"]
EXPOSE 22 3000
ENTRYPOINT ["/app/gogs/docker/start.sh"]
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]
