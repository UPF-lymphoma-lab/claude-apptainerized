# Containerized Claude Code for bioinformatics

## Prerequisites
- Docker installed, current user in the `docker` group.
- A shared lab group GID for `/mnt/data` access — `docker_build.sh`/`export_alias.sh` assume GID `1001`. Edit the `--group-add 1001` line in `export_alias.sh` if it differs on this machine.

## Setup
```bash
git clone <repo-url> ~/claude/claude-setup/claude-code-main
cd ~/claude/claude-setup/claude-code-main
./docker_build.sh          # builds the claude-code-main image
./export_alias.sh          # installs the `claude` shell function into ~/.bashrc
source ~/.bashrc
mkdir -p ~/claude/claude-home   # persistent /home/claude mount
```

`docker_build.sh` hardcodes the clone path (`cd /home/dmitryk/...`) — if cloning elsewhere, edit that path first.

## Usage
From any project directory:
```bash
claude
```
Mounts `$(pwd)` at the same path in the container (workdir too), plus `~/claude/claude-home` as the persistent `/home/claude`. Host UID/GID are passed through so file ownership matches.

To also mount a second host path read-write (e.g. shared data outside the project):
```bash
claude /mnt/data/some/path
```

## Notes
- Container is stateless except for the bind-mounted workspace and `~/claude/claude-home`.
- First run installs R packages into `~/claude/claude-home/R` (persists after).
- `claude` CLI binary is copied to the user's persistent home on first run so `claude update` works.
