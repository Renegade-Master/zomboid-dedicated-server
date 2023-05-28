#   Project Zomboid Dedicated Server using SteamCMD Docker Image.
#   Copyright (C) 2021-2022 Renegade-Master [renegade.master.dev@protonmail.com]
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

#######################################################################
#   Author: Renegade-Master
#   Description: Base image for running a Dedicated Project Zomboid
#       server.
#   License: GNU General Public License v3.0 (see LICENSE)
#######################################################################

# Base Image
ARG BASE_IMAGE="docker.io/renegademaster/steamcmd-minimal:2.0.0-root"
ARG UID=1000
ARG GID=${UID}
ARG RUN_USER=steam

FROM ${BASE_IMAGE}
ARG UID
ARG GID
ARG RUN_USER

USER 0:0

# Add metadata labels
LABEL com.renegademaster.zomboid-dedicated-server.authors="Renegade-Master" \
    com.renegademaster.zomboid-dedicated-server.contributors="JohnEarle, ramielrowe" \
    com.renegademaster.zomboid-dedicated-server.source-repository="https://github.com/Renegade-Master/zomboid-dedicated-server" \
    com.renegademaster.zomboid-dedicated-server.image-repository="https://hub.docker.com/renegademaster/zomboid-dedicated-server"

# Install Python, and take ownership of rcon binary
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-minimal iputils-ping tzdata \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*


# Setup runtime user
RUN groupadd "${RUN_USER}" \
        --gid "${GID}" \
    && useradd "${RUN_USER}" --create-home \
        --uid "${UID}" \
        --gid "${GID}" \
        --home-dir /home/${RUN_USER} \
    && chown -R ${UID}:${GID} /home/${RUN_USER}/

# Login as the runtime user
USER ${RUN_USER}

# Copy the source files
COPY --chown=${RUN_USER} src /home/steam/
COPY --chown=${RUN_USER} --from="docker.io/renegademaster/steamcmd-minimal:2.0.0-root" /home/root/.local/steamcmd /home/steam/.local/steamcmd

# ENV
ENV STEAMDIR=/home/steam/.local/steamcmd
ENV PATH=/home/steam/.local/steamcmd:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Run the setup script
ENTRYPOINT ["/bin/bash", "/home/steam/run_server.sh"]
