# Parallel FastQC on a Slurm cluster

A small training example of how to run the same tool on many samples in
parallel on an HPC cluster using a three-script pattern:

```
makeScriptsForFastQC.sh   ->   FastQC.sh (template)   ->   submitAllScriptsForFastQC.sh
   (generates)                  (one copy per sample)         (submits all to Slurm)
```

## Why three scripts?

You *could* run FastQC on each sample one at a time, but that's slow and
manual. You *could* also write a single big script with a `for` loop, but
then all samples share one Slurm allocation and you lose true parallelism.

The pattern here gives you one Slurm job per sample, all running in parallel
on whatever nodes are free. The cluster's scheduler does the hard work.

## The three scripts

1. **`FastQC.sh`** - the *base template*. It contains all the Slurm directives
   and the actual FastQC commands. The string `BANANA` is a placeholder for
   the sample name. **Don't run this directly.**

2. **`makeScriptsForFastQC.sh`** - finds every `*_R1.fastq.gz` in your data
   directory, extracts the sample name, and uses `sed` to copy the template
   into one per-sample script (e.g. `Sample_42.fastqc.sh`).

3. **`submitAllScriptsForFastQC.sh`** - loops over the generated scripts and
   runs `sbatch` on each. Slurm queues them and runs them in parallel.

## Setup (do this once)

Each script has a `CONFIG` block near the top. Open each file and fill in
the placeholders. You'll need:

- A conda environment with FastQC installed:
  ```
  conda create -n fastqc_env -c bioconda fastqc
  ```
- A folder of paired-end `*_R1.fastq.gz` / `*_R2.fastq.gz` files
- An output folder for FastQC reports
- A folder for Slurm log files
- A folder where the per-sample scripts will live
- The name of a Slurm partition you can submit to (`sinfo` lists them)

The same paths appear in more than one script. The README in each `CONFIG`
block tells you which path should match which.

## How to run

```bash
# 1) Generate one script per sample
bash makeScriptsForFastQC.sh

# 2) Spot-check one of the generated scripts before submitting everything
head /path/to/your/scripts/FastQCscripts/<some_sample>.fastqc.sh

# 3) (Optional) dry-run first - set DRY_RUN="true" at the top of the submit
#    script to see what would be submitted without actually queuing anything
bash submitAllScriptsForFastQC.sh

# 4) Watch your jobs
squeue -u $USER
```

## Troubleshooting

- **All jobs fail instantly** - check the `.err` log in your Slurm logs
  folder. Most often it's a path typo in the `CONFIG` block, or the conda
  env name is wrong.
- **"sbatch: error: Batch job submission failed: Invalid partition"** -
  edit the `#SBATCH -p` line in `FastQC.sh` to a partition that exists on
  your cluster (run `sinfo` to see them).
- **No scripts get generated** - the `find` in `makeScriptsForFastQC.sh`
  uses your `R1_SUFFIX` setting. If your files use `_1.fq.gz` or `.R1.`
  instead, update that variable.
- **Jobs queue forever** - the partition may be busy or you may have
  requested more memory/time than the partition allows. Try a smaller
  request or a different partition.

## File map

| File | Role |
|------|------|
| `FastQC.sh` | Base per-sample template (contains `BANANA`) |
| `makeScriptsForFastQC.sh` | Generates one script per sample |
| `submitAllScriptsForFastQC.sh` | Submits all generated scripts to Slurm |
