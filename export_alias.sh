#!/bin/bash
set -e

# docker run flags:
#   WORKSPACE_ROOT — tells Claude which path is mounted (boundary awareness)
#   USER_ID/GROUP_ID — preserve file ownership
#   --group-add 1001 — grants lab group access
#   $(pwd) expanded at call time because of single quotes
#   mount and workdir use the literal host path so container paths match host paths

alias claude='docker run -it --rm \
  -e WORKSPACE_ROOT=$(pwd) \
  -e USER_ID=$(id -u) \
  -e GROUP_ID=$(id -g) \
  --group-add 1001 \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  -v ~/claude/claude-home:/home/claude \
  claude-code-main'
