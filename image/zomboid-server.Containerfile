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
      glibc.i686 libstdc++.i686 libcurl-minimal.i686 libstdc++.x86_64 musl-libc.x86_64

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

# ldd ProjectZomboid64
#         /lib64/ld-linux-x86-64.so.2 (0x00007f108248c000)
#         libc.so.6 => /lib64/libc.so.6 (0x00007f1081f19000)
#         libdl.so.2 => /lib64/libdl.so.2 (0x00007f1082471000)
#         libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007f10820fb000)
#         libm.so.6 => /lib64/libm.so.6 (0x00007f108211f000)
#         libstdc++.so.6 => /lib64/libstdc++.so.6 (0x00007f1082200000)
#         libsteam_api.so => not found
#         linux-vdso.so.1 (0x00007ffcfb9d6000)

# ldd steamclient.so
#         /lib64/ld-linux-x86-64.so.2 (0x00007fb4773fd000)
#         libc.so.6 => /lib64/libc.so.6 (0x00007fb474db5000)
#         libdl.so.2 => /lib64/libdl.so.2 (0x00007fb47508f000)
#         libm.so.6 => /lib64/libm.so.6 (0x00007fb474fa7000)
#         libpthread.so.0 => /lib64/libpthread.so.0 (0x00007fb474fa2000)
#         librt.so.1 => /lib64/librt.so.1 (0x00007fb47508a000)
#         linux-vdso.so.1 (0x00007ffdbdfe8000)

# ldd steamcmd
#         /lib/ld-linux.so.2 (0xf7f96000)
#         libc.so.6 => /lib/libc.so.6 (0xf7640000)
#         libdl.so.2 => /lib/libdl.so.2 (0xf7918000)
#         libm.so.6 => /lib/libm.so.6 (0xf783f000)
#         libpthread.so.0 => /lib/libpthread.so.0 (0xf783a000)
#         librt.so.1 => /lib/librt.so.1 (0xf7913000)
#         linux-gate.so.1 (0xf7f94000)

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
