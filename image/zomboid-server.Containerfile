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
ARG DOWNLOAD_IMAGE="docker.io/fedora:41"
ARG RCON_IMAGE="docker.io/outdead/rcon:0.10.2"

## DNF and Steam Layer
FROM ${DOWNLOAD_IMAGE} AS downloader

RUN dnf install --verbose --assumeyes --installroot=/app/dnf/ \
    --disablerepo fedora-cisco-openh264 \
      glibc.i686 libstdc++.i686 libcurl-minimal.i686 libstdc++.x86_64

RUN rm -rf /app/dnf/usr/sbin/* /app/dnf/var/cache/* /app/dnf/usr/share/* /app/dnf/usr/lib64/python*

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
ENV LD_LIBRARY_PATH=/usr/local/bin/linux32/:/home/steam/ZomboidDedicatedServer/linux64/:/lib/:/lib64/:$LD_LIBRARY_PATH \
  PATH=/usr/local/bin/linux32/:/app/$PATH

# ldd /home/steam/ZomboidDedicatedServer/ProjectZomboid64 | cut  -d ' ' -f 1 | xargs -I {} find / -iname "*{}*"
# ldd ProjectZomboid64
#         /lib64/ld-linux-x86-64.so.2 (0x00007fa1d27b1000)
#         libc.so.6 => /lib64/libc.so.6 (0x00007fa1d2246000)
#         libdl.so.2 => /lib64/libdl.so.2 (0x00007fa1d27a8000)
#         libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007fa1d2435000)
#         libm.so.6 => /lib64/libm.so.6 (0x00007fa1d2462000)
#         libstdc++.so.6 => /lib64/libstdc++.so.6 (0x00007fa1d2545000)
#         libsteam_api.so => not found
#         linux-vdso.so.1 (0x00007ffcf6ed0000)
# COPY --from=downloader [ \
#     "/app/dnf/usr/lib64/ld-linux-x86-64.so.2", \
#     "/app/dnf/usr/lib64/libc.so.6", \
#     "/app/dnf/usr/lib64/libdl.so.2", \
#     "/app/dnf/usr/lib64/libgcc_s.so.1", \
#     "/app/dnf/usr/lib64/libm.so.6", \
#     "/app/dnf/usr/lib64/libstdc++.so.6", \
#     "/app/dnf/usr/lib64/libstdc++.so.6.0.33", \
#     "/lib64/" \
# ]

# ldd /usr/local/bin/linux32/steamclient.so | cut  -d ' ' -f 1 | xargs -I {} find / -iname "*{}*"
# ldd steamclient.so
#         /lib/ld-linux.so.2 (0xf7ed4000)
#         libc.so.6 => /lib/libc.so.6 (0xf56e5000)
#         libdl.so.2 => /lib/libdl.so.2 (0xf59bc000)
#         libm.so.6 => /lib/libm.so.6 (0xf58e3000)
#         libpthread.so.0 => /lib/libpthread.so.0 (0xf58de000)
#         librt.so.1 => /lib/librt.so.1 (0xf59b7000)
#         linux-gate.so.1 (0xf7ed2000)
# COPY --from=downloader [ \
#     "/app/dnf/usr/lib/ld-linux.so.2", \
#     "/app/dnf/usr/lib/libc.so.6", \
#     "/app/dnf/usr/lib/libdl.so.2", \
#     "/app/dnf/usr/lib/libm.so.6", \
#     "/app/dnf/usr/lib/libpthread.so.0", \
#     "/app/dnf/usr/lib/librt.so.1", \
#     "/lib/" \
# ]

# ldd /usr/local/bin/linux32/steamcmd | cut  -d ' ' -f 1 | xargs -I {} find / -iname "*{}*"
# ldd steamcmd
#        /lib/ld-linux.so.2 (0xf7f26000)
#        libc.so.6 => /lib/libc.so.6 (0xf7802000)
#        libdl.so.2 => /lib/libdl.so.2 (0xf7ad4000)
#        libm.so.6 => /lib/libm.so.6 (0xf79fb000)
#        libpthread.so.0 => /lib/libpthread.so.0 (0xf7acf000)
#        librt.so.1 => /lib/librt.so.1 (0xf7ad9000)
#        linux-gate.so.1 (0xf7f24000)

# ldd /app/zomboid-server | cut  -d ' ' -f 1 | xargs -I {} find / -iname "*{}*"
# ldd zomboid-server
#         /lib64/ld-linux-x86-64.so.2 (0x00007f98ca05e000)
#         libc.so.6 => /lib64/libc.so.6 (0x00007f98c9e56000)
#         libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f98ca043000)
#         libresolv.so.2 => /lib64/libresolv.so.2 (0x00007f98ca048000)
#         linux-vdso.so.1 (0x00007ffc8b1bf000)
# COPY --from=downloader [ \
#     "/app/dnf/usr/lib64/libpthread.so.0", \
#     "/app/dnf/usr/lib64/libresolv.so.2", \
#     "/lib64/" \
# ]

# ldd /usr/bin/bash | cut  -d ' ' -f 1 | xargs -I {} find / -iname "*{}*"
# ldd bash
#         /lib64/ld-linux-x86-64.so.2 (0x00007f95a1079000)
#         libc.so.6 => /usr/lib64/libc.so.6 (0x00007f95a0cff000)
#         libtinfo.so.6 => /usr/lib64/libtinfo.so.6 (0x00007f95a0eec000)
#         linux-vdso.so.1 (0x00007ffe8c2c0000)
# COPY --from=downloader [ \
#     "/app/dnf/usr/lib64/libtinfo.so.6", \
#     "/app/dnf/usr/lib64/libtinfo.so.6.4", \
#     "/lib64/" \
# ]
# COPY --from=downloader [ \
#     "/usr/lib64/libtinfo.so.6", \
#     "/lib/" \
# ]

# Copy required System Utils
COPY --from=downloader [ \
    "/usr/bin/bash", \
    "/usr/bin/basename", \
    "/usr/bin/env", \
    "/usr/bin/uname", \
    "/usr/bin/" \
]

# COPY --from=downloader  /etc/pki/ /etc/pki/
# COPY --from=downloader  /etc/ssl/ /etc/ssl/
COPY --from=downloader /app/dnf/ /

# Copy the SteamCMD installation
COPY --from=downloader /app/steam/out/ /usr/local/bin/
COPY --from=builder /app/out/ /app/

# Copy server utilities
COPY --from="docker.io/outdead/rcon:0.10.2" /rcon /usr/local/bin/rcon
COPY --from="docker.io/outdead/rcon:0.10.2" /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1

# Copy SteamCMD configuration script
COPY static/install_server.scmd /app/

ENTRYPOINT [ "/app/zomboid-server" ]
