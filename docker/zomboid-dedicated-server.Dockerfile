#######################################################################
#   Author: Renegade-Master
#   Description: Base image for running a Dedicated Project Zomboid
#       server.
#   License: GNU General Public License v3.0 (see LICENSE)
#######################################################################

# Set the User and Group IDs
ARG USER_ID=1000
ARG GROUP_ID=1000

FROM renegademaster/steamcmd-minimal:1.0.0
ARG USER_ID
ARG GROUP_ID

# Add metadata labels
LABEL com.renegademaster.zomboid-dedicated-server.authors="Renegade-Master" \
    com.renegademaster.zomboid-dedicated-server.contributors="JohnEarle" \
    com.renegademaster.zomboid-dedicated-server.source-repository="https://github.com/Renegade-Master/zomboid-dedicated-server" \
    com.renegademaster.zomboid-dedicated-server.image-repository="https://hub.docker.com/renegademaster/zomboid-dedicated-server"

# Copy the source files
COPY src /home/steam/

# Temporarily login as root to modify ownership
USER 0:0
RUN chown -R ${USER_ID}:${GROUP_ID} "/home/steam"

# Switch to the Steam User
USER ${USER_ID}:${GROUP_ID}

# Run the setup script
ENTRYPOINT ["/bin/bash", "/home/steam/run_server.sh"]
