#!/bin/bash
# Builds claude.sif next to this script. Run as root or as a regular user with /etc/subuid entries.
# base.sif (system packages, R, Python, tools) is rebuilt only when base.def is newer
# than it or when called with --base; claude.sif is always rebuilt on top of it.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# root builds directly; regular users need fakeroot
fakeroot=()
[ "$(id -u)" = 0 ] || fakeroot=(--fakeroot)

if [ "${1:-}" = "--base" ] || [ ! -f base.sif ] || [ base.def -nt base.sif ]; then
  mirror=()
  [ -n "${UBUNTU_MIRROR:-}" ] && mirror=(--build-arg "UBUNTU_MIRROR=$UBUNTU_MIRROR")
  apptainer build "${fakeroot[@]}" --force "${mirror[@]}" base.sif base.def
fi
apptainer build "${fakeroot[@]}" --force claude.sif claude.def
