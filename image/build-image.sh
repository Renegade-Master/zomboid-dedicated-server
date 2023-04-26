#!/usr/bin/env bash
set +x -euo pipefail

FEDORA_IMAGE="docker.io/fedora:39"
RCON_IMAGE="docker.io/outdead/rcon:0.10.2"

# Create the containers for building the image
downloadCtr=$(buildah from scratch)
workingCtr=$(buildah from scratch)
fedoraCtr=$(buildah from ${FEDORA_IMAGE})
rconCtr=$(buildah from ${RCON_IMAGE})

# Create some directories for storing the working directories
workDir=$(pwd)
downloadMnt=$(buildah mount "${downloadCtr}")
workingMnt=$(buildah mount "${workingCtr}")
rconMnt=$(buildah mount "${rconCtr}")

mkdir -p "${workingMnt}/etc/"
touch "${workingMnt}/etc/passwd" "${workingMnt}/etc/shadow" "${workingMnt}/etc/group"

# Create the Steam user
buildah run \
  --mount type=bind,source="${workingMnt}/etc/passwd",target=/etc/passwd:z \
  --mount type=bind,source="${workingMnt}/etc/shadow",target=/etc/shadow:z \
  --mount type=bind,source="${workingMnt}/etc/group",target=/etc/group:z \
  "${fedoraCtr}" \
  -- \
  useradd \
      --base-dir "${workingMnt}/home" \
      --comment "Steam user" \
      --home-dir "${workingMnt}/home/steam" \
      --create-home \
      --no-user-group \
      --uid 666 \
      steam

# CD into the Download directory, and download Steam
cd "${downloadMnt}"
mkdir -p "${workingMnt}/home/steam/.local/steamcmd/"
wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
tar --directory="${workingMnt}/home/steam/.local/steamcmd/" -zxf steamcmd_linux.tar.gz
rm steamcmd_linux.tar.gz

cd "${workDir}"

# Install the dependencies
dnf install \
  --assumeyes \
  --installroot "${workingMnt}" \
  --releasever 39 \
  --setopt install_weak_deps=false \
  --repo fedora \
  bash python3 hostname tzdata

dnf --installroot "${workingMnt}" clean all

# Copy files from the repo into the image
cp "${workDir}/src/edit_server_config.py" "${workingMnt}/usr/bin"
cp "${workDir}/src/install_server.scmd" "${workingMnt}/usr/bin"
cp "${workDir}/src/run_server.sh" "${workingMnt}/usr/bin"
cp "${rconMnt}/rcon" "${workingMnt}/usr/bin/rcon"

mkdir -p "${workingMnt}/home/steam/ZomboidDedicatedServer" "${workingMnt}/home/steam/ZomboidConfig"

buildah run \
  --mount type=bind,source="${workingMnt}/etc/passwd",target=/etc/passwd:z \
  --mount type=bind,source="${workingMnt}/etc/shadow",target=/etc/shadow:z \
  --mount type=bind,source="${workingMnt}/etc/group",target=/etc/group:z \
  "${fedoraCtr}" \
  -- \
  chown -R steam "${workingMnt}/home/steam/"

# Unmount the working directories
buildah umount "${workingCtr}"
buildah umount "${downloadCtr}"
buildah umount "${rconCtr}"

# Set configurations for the image
buildah config --env "PATH=/home/steam/.local/bin:/home/steam/.local/steamcmd:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" "${workingCtr}"
buildah config --cmd "/usr/bin/run_server.sh" "${workingCtr}"

#BUILDAH_ISOLATION="chroot ${workingCtr}"
buildah commit "${workingCtr}" localhost/buildah-scratch-test:latest

# Remove working containers
buildah rm "${workingCtr}"
buildah rm "${downloadCtr}"
