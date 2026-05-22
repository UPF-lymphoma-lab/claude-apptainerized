#!/bin/bash
set -e

# docker run flags:
#   HOST_WORKSPACE — lets Claude know the real host path (since it runs in a container)
#   USER_ID/GROUP_ID — preserve file ownership
#   --group-add 1001 — grants lab group access
#   $(pwd) expanded at call time because of single quotes

alias claude='docker run -it --rm \
  -e HOST_WORKSPACE=$(pwd) \
  -e USER_ID=$(id -u) \
  -e GROUP_ID=$(id -g) \
  --group-add 1001 \
  -v $(pwd):/workspace \
  -v ~/claude/claude-home:/home/claude \
  claude-code-main'
