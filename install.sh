#!/bin/bash
# Installs claude.sif to /opt/claude-code (readable by the lab group) and the
# launcher to /usr/local/bin/claude. Run with sudo after build.sh.
set -euo pipefail

[ "$(id -u)" = 0 ] || { echo "run with sudo" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GROUP="${CLAUDE_GROUP:-lab-pk}"

install -d -m 750 -o root -g "$GROUP" /opt/claude-code
# Copy then rename so running sessions keep their image
install -m 640 -o root -g "$GROUP" "$SCRIPT_DIR/claude.sif" /opt/claude-code/claude.sif.new
mv -f /opt/claude-code/claude.sif.new /opt/claude-code/claude.sif
install -m 755 -o root -g root "$SCRIPT_DIR/claude" /usr/local/bin/claude

echo "Installed /opt/claude-code/claude.sif and /usr/local/bin/claude for group $GROUP"
