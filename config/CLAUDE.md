# Lab working environment

You run inside an Apptainer container on the lab server, as the user who started you. Files you create belong to that user and, in lab project folders, to the lab group; treat every change as made on the user's behalf.

Inside the container the lab group appears as `nogroup` (GID 65534) in `id` and `ls -l`, because host groups are not mapped into the container. Access checks still use the real groups, and files created in setgid project folders belong to the lab group on the host. Do not try to `chgrp` or `chmod` files to fix this.

## What you can see
- The current project folder (`$WORKSPACE_ROOT`), mounted at the same path as on the host. An optional second folder (`$SECONDARY_WORKSPACE`, also passed with `--add-dir`) is mounted read-write at its host path.
- The user's mamba installation and environment folders, at the same paths as on the host.
- A persistent private home folder (`/home/claude`, on the host `~/claude/claude-home`). The user's real home folder is not visible.
- Nothing else from the host. If a path is missing, ask the user to run the command on the host instead of searching for it.

The container exists only while Claude Code runs; `/tmp` is wiped on exit. Anything that must outlast the session belongs in the project folder or the home folder.

## Software
- In the image: R (tidyverse, qs2, hdf5r, Seurat, plus headers for building packages from source), Python 3 (pandas, numpy, scipy, matplotlib, seaborn, pysam, h5py, anndata, openpyxl), samtools, bcftools, bedtools, tabix/bgzip, mosdepth, git, gh, pandoc, Node.js, Java.
- R packages the user installs go to `~/R/library` in the home folder and persist. That library comes first, so a package installed there is used instead of the image's copy (check with `find.package()`).
- The image is read-only: there is no `sudo`/`apt`. Install software into the home folder or a mamba environment.

## mamba environments
- `mamba` is the user's host installation; its environments are shared with the host and keep working without this container.
- Run tools non-interactively: `mamba run -n ENV command`. `mamba activate` does not work in your shell.
- List environments with `mamba env list` before creating new ones; reuse a fitting one.
- Create or modify environments only after the user agrees.
- After creating or changing an environment for a project, export it into the project:
  `mamba env export -n ENV --no-builds > environment.yml`
  (use `envs/ENV.yml` when a project uses several environments).
- Older micromamba environments may exist in `~/micromamba`; they work only inside this container (`micromamba -r ~/micromamba run -n ENV command`). Prefer host mamba environments for new work.
- If `mamba` reports no host installation, environments land in the home folder and work only inside this container; tell the user.

## Heavy work and pipelines
Long or resource-heavy jobs (Nextflow, Snakemake, alignment, large batch jobs) are run by the user on the host. Write the scripts and the exact commands, and leave running them to the user.

There is no apptainer, singularity or docker inside this container. Pipelines that run their steps in containers (`snakemake --sdm apptainer`, `--use-singularity`, `nextflow -profile singularity`) cannot run here. What you can do:
- write and edit workflow files, configs and sample sheets;
- check them with a dry run and lint from a snakemake environment, without the container flags: `mamba run -n ENV snakemake -n` and `mamba run -n ENV snakemake --lint` (find ENV with `mamba env list`);
- give the user the full command to run on the host, from the project folder.

## Data protection
The lab handles patient data. Do not copy data outside the project folder, upload it, or paste file contents into external services. Read only what the task needs.

## Personal instructions
This file holds lab-wide defaults and is updated with the container image. Personal preferences go in `~/.claude/CLAUDE.md` (on the host `~/claude/claude-home/.claude/CLAUDE.md`); suggest adding a note there when the user states a lasting preference.
