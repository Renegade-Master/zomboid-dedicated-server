#!/usr/bin/env bash
set +x -euo pipefail

RCON_IMAGE="docker.io/outdead/rcon:0.10.2"

dwnldr=$(buildah from scratch)
wkcntr=$(buildah from scratch)
rccntr=$(buildah from ${RCON_IMAGE})

wkdir=$(pwd)
dwnmnt=$(buildah mount "${dwnldr}")
wrkmnt=$(buildah mount "${wkcntr}")
rcnmnt=$(buildah mount "${rccntr}")

cd "${dwnmnt}"
mkdir -p "${wrkmnt}/home/steam/.local/steamcmd/"
wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
tar --directory="${wrkmnt}/home/steam/.local/steamcmd/" -zxf steamcmd_linux.tar.gz
rm steamcmd_linux.tar.gz

cd "${wkdir}"

dnf install \
  --assumeyes \
  --installroot "${wrkmnt}" \
  --releasever 36 \
  --setopt install_weak_deps=false \
  bash python3 hostname tzdata

dnf --installroot "${wrkmnt}" clean all

cp "${wkdir}/src/edit_server_config.py" "${wrkmnt}/usr/bin"
cp "${wkdir}/src/install_server.scmd" "${wrkmnt}/usr/bin"
cp "${wkdir}/src/run_server.sh" "${wrkmnt}/usr/bin"
cp "${rcnmnt}/rcon" "${wrkmnt}/usr/bin/rcon"

buildah umount "${wkcntr}"
buildah umount "${dwnldr}"
buildah umount "${rccntr}"

buildah config --env "PATH=/home/steam/.local/steamcmd/:\$PATH" "${wkcntr}"
buildah config --cmd "/usr/bin/run_server.sh" "${wkcntr}"

#BUILDAH_ISOLATION="chroot ${wkcntr}"
buildah commit "${wkcntr}" localhost/buildah-scratch-test:latest

buildah rm "${wkcntr}"
buildah rm "${dwnldr}"
