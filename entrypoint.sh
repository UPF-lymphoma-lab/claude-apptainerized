#!/bin/bash
set -e

# ============================================
# RUNTIME UID/GID MAPPING (START)
# Runs as root, then drops to claude user
# ============================================
TARGET_UID="${USER_ID:-1000}"
TARGET_GID="${GROUP_ID:-1000}"
CURRENT_UID=$(id -u claude)
CURRENT_GID=$(id -g claude)

if [ "$(id -u)" = "0" ]; then
    # Remap claude user/group to match host UID/GID
    if [ "$CURRENT_GID" != "$TARGET_GID" ]; then
        groupmod -g "$TARGET_GID" claude 2>/dev/null || true
    fi
    if [ "$CURRENT_UID" != "$TARGET_UID" ]; then
        usermod -u "$TARGET_UID" claude 2>/dev/null || true
    fi

    # Fix ownership of non-mounted dirs that still have old UID
    chown claude:claude /home/claude 2>/dev/null || true

    # Add supplementary groups (e.g. shared lab group for file access)
    # EXTRA_GROUPS is a colon-separated list of GIDs, e.g. "1001:1002"
    if [ -n "${EXTRA_GROUPS:-}" ]; then
        IFS=':' read -ra GIDS <<< "$EXTRA_GROUPS"
        for gid in "${GIDS[@]}"; do
            groupadd -g "$gid" "group_$gid" 2>/dev/null || true
            usermod -aG "group_$gid" claude
        done
    fi

    # Re-run this script as claude
    exec gosu claude "$0" "$@"
fi
# ============================================
# RUNTIME UID/GID MAPPING (END)
# ============================================

# ============================================
# DOTFILE BOOTSTRAP (START)
# Create essential dotfiles if missing in
# the mounted home (first run for new users)
# ============================================
if [ ! -f "$HOME/.Renviron" ]; then
    echo 'R_LIBS_USER="~/R/library"' > "$HOME/.Renviron"
    echo "Created ~/.Renviron"
fi

if [ ! -f "$HOME/.bashrc" ]; then
    cp /etc/skel/.bashrc "$HOME/.bashrc" 2>/dev/null || true
    echo "Created ~/.bashrc"
fi

if [ ! -f "$HOME/.profile" ]; then
    cp /etc/skel/.profile "$HOME/.profile" 2>/dev/null || true
    echo "Created ~/.profile"
fi

mkdir -p "$HOME/.claude"
# ============================================
# DOTFILE BOOTSTRAP (END)
# ============================================

# ============================================
# R PACKAGES INSTALLATION (START)
# First-run installation into persistent home
# Delete ~/R/.packages-installed to reinstall
# ============================================
if [ -f /opt/install-r-packages.R ]; then
    mkdir -p "$HOME/R/library"

    if [ ! -f "$HOME/R/.packages-installed" ]; then
        echo "First run: installing R packages to persistent home..."
        echo "This may take a while. Subsequent runs will skip this step."
        Rscript /opt/install-r-packages.R
        touch "$HOME/R/.packages-installed"
        echo "R packages installed successfully."
    fi
fi
# ============================================
# R PACKAGES INSTALLATION (END)
# ============================================

# Ensure user has their own claude binary so `claude update` works and persists
mkdir -p "$HOME/.local/bin"
if [ ! -f "$HOME/.local/bin/claude" ]; then
    cp /usr/local/bin/claude "$HOME/.local/bin/claude"
fi
export PATH="$HOME/.local/bin:$PATH"

# ============================================
# SESSION REGISTRATION (START)
# ============================================
SESSION_NAME=$(openssl rand -hex 4)
SESSIONS_FILE="$HOME/.claude/workspace-sessions.json"
LOCK_DIR="$HOME/.claude/session-locks"
mkdir -p "$LOCK_DIR"

# Hold a lifetime lock; the kernel releases it when this process dies, even on
# an abrupt crash. New sessions probe these locks to prune dead entries.
exec {SESSION_FD}>"$LOCK_DIR/$SESSION_NAME"
flock -x "$SESSION_FD"

python3 - "$SESSIONS_FILE" "$LOCK_DIR" "$SESSION_NAME" "$WORKSPACE_ROOT" <<'PYEOF'
import json, os, sys, subprocess, fcntl
sessions_file, lock_dir, name, workspace = sys.argv[1:5]
reg = open(sessions_file + ".lock", "w")
fcntl.flock(reg, fcntl.LOCK_EX)
data = json.load(open(sessions_file)) if os.path.exists(sessions_file) else {}
data[name] = workspace
alive = {}
for n, ws in data.items():
    if n == name:
        alive[n] = ws
        continue
    lock = os.path.join(lock_dir, n)
    # Non-blocking lock succeeds only if no live session holds it -> dead.
    if subprocess.call(["flock", "-n", lock, "-c", "true"]) != 0:
        alive[n] = ws            # busy -> alive, keep
    else:
        try: os.remove(lock)     # acquired -> stale, drop entry + lockfile
        except OSError: pass
json.dump(alive, open(sessions_file, "w"), indent=2)
PYEOF
# ============================================
# SESSION REGISTRATION (END)
# ============================================

"$@"; EXIT_CODE=$?

# ============================================
# SESSION CLEANUP
# ============================================
python3 - <<PYEOF
import json, os, fcntl
path = "$SESSIONS_FILE"
lock = open(path + ".lock", "w")
fcntl.flock(lock, fcntl.LOCK_EX)
if os.path.exists(path):
    data = json.load(open(path))
    data.pop("$SESSION_NAME", None)
    json.dump(data, open(path, "w"), indent=2)
try:
    os.remove("$LOCK_DIR/$SESSION_NAME")
except OSError:
    pass
PYEOF

exit $EXIT_CODE
