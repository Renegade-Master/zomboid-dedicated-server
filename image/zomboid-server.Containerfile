#
# Copyright 2021-2024 Renegade-Master [renegade@renegade-master.com]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG BUILDER_IMAGE="docker.io/golang:1.21.6-bullseye"
ARG DOWNLOAD_IMAGE="docker.io/fedora:40"
ARG RCON_IMAGE="docker.io/outdead/rcon:0.10.2"

## DNF and Steam Layer
FROM ${DOWNLOAD_IMAGE} AS downloader

RUN dnf install --verbose --assumeyes --installroot=/app/dnf/ \
    --disablerepo fedora-cisco-openh264 \
      glibc.i686 libstdc++.i686 libcurl-minimal.i686 libstdc++.x86_64 musl-libc.x86_64

RUN rm -rf /app/dnf/var/cache/* /app/dnf/usr/share/*

WORKDIR /app/steam/

RUN curl -LO "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
RUN mkdir out
RUN tar -xvzf steamcmd_linux.tar.gz -C out/

## Builder Layer
FROM ${BUILDER_IMAGE} AS builder

WORKDIR "/app/"

COPY . /app/

RUN go build -o /app/out/ ./...

## Runtime Layer
FROM scratch AS final

# Include the Steam dependencies in the Library Path
ENV LD_LIBRARY_PATH=/usr/local/bin/linux32:$LD_LIBRARY_PATH \
  PATH=/usr/local/bin/linux32/:$PATH

# Copy required System Utils
COPY --from=downloader [ \
    "/usr/bin/bash", \
    "/usr/bin/basename", \
    "/usr/bin/env", \
    "/usr/bin/uname", \
    "/usr/bin/" \
]

COPY --from=downloader /app/dnf/ /

# Copy the DNF x32 dependencies
# COPY --from=downloader [ \
#     "/app/dnf/usr/lib/ld-musl-x86_64.so.1", \
#     "/app/dnf/usr/lib/libc.so.6", \
#     "/app/dnf/usr/lib/libdl.so.2", \
#     "/app/dnf/usr/lib/libm.so.6", \
#     "/app/dnf/usr/lib/libpthread.so.0", \
#     "/app/dnf/usr/lib/librt.so.1", \
#     "/usr/lib/" \
# ]

# Copy the DNF x64 dependencies
# COPY --from=downloader [ \
#     "/app/dnf/usr/lib64/ld-linux-x86-64.so.2", \
#     "/app/dnf/usr/lib64/libc.so.6", \
#     "/app/dnf/usr/lib64/libdl.so.2", \
#     "/app/dnf/usr/lib64/libgcc_s.so.1", \
#     "/app/dnf/usr/lib64/libm.so.6", \
#     "/app/dnf/usr/lib64/libpthread.so.0", \
#     "/app/dnf/usr/lib64/libresolv.so.2", \
#     "/app/dnf/usr/lib64/libstdc++.so.6", \
#     "/app/dnf/usr/lib64/libtinfo.so.6", \
#     "/usr/lib64/" \
# ]
#     "/app/dnf/usr/lib64/libsteam_api.so" \
#     "/app/dnf/usr/lib64/linux-vdso.so.1" \

# Copy the SteamCMD installation
COPY --from=downloader /app/steam/out/ /usr/local/bin/
COPY --from=builder /app/out/ /app/

# Copy server utilities
COPY --from="docker.io/outdead/rcon:0.10.2" /rcon /usr/local/bin/rcon

# Copy SteamCMD configuration script
COPY static/install_server.scmd /app/

ENTRYPOINT [ "/app/zomboid-server" ]
