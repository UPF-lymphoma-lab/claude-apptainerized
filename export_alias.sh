#!/bin/bash
set -e

# docker run flags:
#   WORKSPACE_ROOT — tells Claude which path is mounted (boundary awareness)
#   USER_ID/GROUP_ID — preserve file ownership
#   --group-add 1001 — grants lab group access
#   $(pwd) expanded at call time because of single quotes
#   mount and workdir use the literal host path so container paths match host paths
#   optional $1 — second host path, mounted read-write at the same path in the container

# Persist the function directly in ~/.bashrc
TMPFILE=$(mktemp)
cat > "$TMPFILE" << 'EOF'
# BEGIN claude-code alias
claude() {
  local extra_mount=() extra_env=()
  if [ -n "$1" ]; then
    extra_mount=(-v "$1:$1")
    extra_env=(-e SECONDARY_WORKSPACE="$1")
  fi
  docker run -it --rm \
    -e WORKSPACE_ROOT="$(pwd)" \
    -e USER_ID="$(id -u)" \
    -e GROUP_ID="$(id -g)" \
    --group-add 1001 \
    -v "$(pwd):$(pwd)" \
    -w "$(pwd)" \
    -v ~/claude/claude-home:/home/claude \
    "${extra_mount[@]}" \
    "${extra_env[@]}" \
    claude-code-main
}
# END claude-code alias
EOF

python3 - "$TMPFILE" << 'PYEOF'
import sys, os, re
new_block = open(sys.argv[1]).read().strip()
bashrc_path = os.path.expanduser('~/.bashrc')
content = open(bashrc_path).read() if os.path.exists(bashrc_path) else ''
pattern = r'# BEGIN claude-code alias.*?# END claude-code alias'
if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, new_block, content, flags=re.DOTALL)
else:
    content = content.rstrip('\n') + '\n\n' + new_block + '\n'
open(bashrc_path, 'w').write(content)
PYEOF

rm "$TMPFILE"
