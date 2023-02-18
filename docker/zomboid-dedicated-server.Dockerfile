#   Project Zomboid Dedicated Server using SteamCMD Docker Image.
#   Copyright (C) 2021-2023 Renegade-Master [renegade.master.dev@protonmail.com]
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
ARG BASE_IMAGE="docker.io/renegademaster/steamcmd-minimal:2.0.0"
ARG UID=1000
ARG GID=${UID}
ARG USER=steam

FROM ${BASE_IMAGE}
ARG UID
ARG GID
ARG USER

# Add metadata labels
LABEL com.renegademaster.zomboid-dedicated-server.authors="Renegade-Master" \
    com.renegademaster.zomboid-dedicated-server.contributors="JohnEarle, ramielrowe" \
    com.renegademaster.zomboid-dedicated-server.source-repository="https://github.com/Renegade-Master/zomboid-dedicated-server" \
    com.renegademaster.zomboid-dedicated-server.image-repository="https://hub.docker.com/renegademaster/zomboid-dedicated-server"

USER 0:0

# Install Python, and take ownership of rcon binary
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3-minimal iputils-ping \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /home/steam/Zomboid /home/steam/ZomboidDedicatedServer

RUN chown -R ${UID}:${GID} /home/steam/ /home/steam/Zomboid /home/steam/ZomboidDedicatedServer \
    && chmod -R 2777 /home/steam/Zomboid /home/steam/ZomboidDedicatedServer

USER ${UID}:${GID}

# Copy the source files
COPY --chown=${UID}:${GID} src /home/steam/

# Run the setup script
ENTRYPOINT ["/bin/bash", "/home/steam/run_server.sh"]
