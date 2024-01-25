ARG BUILDER_IMAGE="docker.io/golang:1.21.6-bullseye"
ARG DOWNLOAD_IMAGE="docker.io/fedora:40"
ARG RCON_IMAGE="docker.io/outdead/rcon:0.10.2"

# Steam Layer
FROM ${DOWNLOAD_IMAGE} AS steam

RUN dnf install --verbose --assumeyes --installroot=/app/dnf/ \
    --disablerepo fedora-cisco-openh264 \
      glibc.i686 libstdc++.i686

WORKDIR /app/steam/

RUN curl -LO "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
RUN mkdir out
RUN tar -xvzf steamcmd_linux.tar.gz -C out/

# Builder Layer
FROM ${BUILDER_IMAGE} AS builder

WORKDIR "/app/"

COPY . /app/

RUN go build -o /app/out/ ./...

FROM scratch AS final

COPY --from=builder /app/out/ /app/
COPY --from=steam /app/dnf /
COPY --from=steam /app/steam/out/linux32/ /usr/local/lib/
COPY --from=steam /app/steam/out/linux32/steamcmd /usr/local/bin/steamcmd
COPY --from="docker.io/outdead/rcon:0.10.2" /rcon /usr/local/bin/rcon

COPY static/install_server.scmd /app/

ENTRYPOINT [ "/app/zomboid-dedicated-server" ]
