# Containerized Claude Code for the lab

Claude Code runs in an Apptainer container as the calling user. It sees only the current project folder, an optional second folder, the user's mamba environments, and a private persistent home (`~/claude/claude-home`, mounted as `/home/claude`). Files it creates are owned by the user and group-writable (`umask 002`); in setgid project folders they get the folder's group.

## For users

From a project folder:
```bash
cd /mnt/data/NGS/Projects/MY_PROJECT
claude                               # Claude works in this folder
claude /mnt/data/NGS/Projects/OTHER  # also gives read-write access to a second folder
claude --resume                      # other arguments go to Claude Code
```

On the first run Claude Code is installed into the home folder and asks you to sign in: open the link it prints in any browser and paste the code back.

`claude` refuses to start in parents of your home folder, system folders, or shared roots like `/mnt/data`.

Each session is a container that exists only while Claude Code runs: on exit, everything running inside it stops. Conversations are kept, so `claude --resume` (from the same project folder) continues one.

Inside the container: R with tidyverse, qs2, hdf5r and Seurat, plus headers for building R packages from source; Python with pandas/numpy/scipy/matplotlib, pysam, h5py and anndata; samtools, bcftools, bedtools, tabix/bgzip, mosdepth; git, gh, pandoc, Node.js, Java. Personal R packages install to `~/R/library` inside the home and persist.

`mamba` inside the container is the host installation (detected from `MAMBA_ROOT_PREFIX`, `CONDA_EXE`, `/opt/miniforge3`, `~/miniforge3`; override with `CLAUDE_MAMBA_ROOT`). It is mounted at its host path together with the environment and package folders from `~/.condarc`, so environments created by Claude work on the host as well. Without a host installation, `mamba` falls back to the bundled micromamba and its environments live only in the home.

Lab-wide instructions for Claude are in `/etc/claude-code/CLAUDE.md` inside the image (`config/CLAUDE.md` here) and update with the image. Personal instructions go in `~/claude/claude-home/.claude/CLAUDE.md`.

The launcher sets `WORKSPACE_ROOT` (the project folder) and, with a second folder, `SECONDARY_WORKSPACE`.

## For the admin

Build as a regular user (needs `/etc/subuid` entries), then install as root:
```bash
./build.sh            # creates claude.sif
sudo ./install.sh     # /opt/claude-code/claude.sif (group lab-pk, 640) and /usr/local/bin/claude
```

The image is built in two stages. `base.def` → `base.sif` holds the slow parts (system packages, R, Python, bioinformatics tools) and is rebuilt only when `base.def` changes or with `./build.sh --base` (e.g. to pick up package updates). `claude.def` → `claude.sif` adds `config/` and the startup script on top of `base.sif`, so changes there rebuild quickly.

`install.sh` takes the group from `CLAUDE_GROUP` (default `lab-pk`). Only members of that group can run the image.

Claude Code updates itself: the image installs it into each user's home (`~/.local/bin/claude`, versions in `~/.local/share/claude`) on first run, and it updates that copy. Rebuilding the image does not change the version users run.

Build with the default `APPTAINER_TMPDIR` (`/tmp`): with `--fakeroot`, unpacking `base.sif` for the second stage fails when it points to `/mnt/scratch`.

## Isolation

The launcher uses `apptainer run --containall` (no host home, clean environment, private `/tmp`, PID and IPC namespaces) with explicit binds only. The host network is shared. Proxy variables are forwarded if set.

Claude Code's own bubblewrap sandbox is off by default. Claude Code is started in a nested user and mount namespace so that the sandbox works inside Apptainer if enabled in settings.
