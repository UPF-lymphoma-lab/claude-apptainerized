#!/bin/bash
set -e

# docker run flags:
#   WORKSPACE_ROOT — tells Claude which path is mounted (boundary awareness)
#   USER_ID/GROUP_ID — preserve file ownership
#   --group-add 1001 — grants lab group access
#   $(pwd) expanded at call time because of single quotes
#   mount and workdir use the literal host path so container paths match host paths

# Persist the alias directly in ~/.bashrc
TMPFILE=$(mktemp)
cat > "$TMPFILE" << 'EOF'
# BEGIN claude-code alias
alias claude='docker run -it --rm \
  -e WORKSPACE_ROOT=$(pwd) \
  -e USER_ID=$(id -u) \
  -e GROUP_ID=$(id -g) \
  --group-add 1001 \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  -v ~/claude/claude-home:/home/claude \
  claude-code-main'
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
