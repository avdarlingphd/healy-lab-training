#!/bin/bash
###############################################################################
# FastQC.sh - PER-SAMPLE base script (template)
#
# WHAT THIS SCRIPT DOES
#   Runs FastQC on the paired-end FASTQ files for ONE sample. This is the
#   "base" template - one copy of it will be created for every sample by
#   makeScriptsForFastQC.sh (the placeholder "BANANA" gets replaced with
#   the actual sample name).
#
# WHEN IT RUNS
#   Submitted to Slurm by submitAllScriptsForFastQC.sh - one job per sample,
#   all running in parallel on the cluster.
#
# HOW TO USE
#   1) Fill in the CONFIG block below.
#   2) Do NOT change the SAMPLE="BANANA" line - the make-scripts step relies
#      on it as a find/replace marker.
###############################################################################

# ============================================================================
# SLURM CONFIG - resource requests for ONE sample's FastQC job
# ============================================================================
#SBATCH -J fastqc                       # job name shown in squeue
#SBATCH -c 1                            # CPUs per task (FastQC is single-threaded per file)
#SBATCH -t 0-09:00                      # walltime D-HH:MM (9 hours is generous)
#SBATCH --mem=4G                        # RAM per job
#SBATCH -p PARTITION_NAME               # CHANGE ME: e.g. "shared" or "general"
#SBATCH -o /path/to/your/slurm_logs/%j.FastQC.out   # CHANGE ME: stdout log (%j = job ID)
#SBATCH -e /path/to/your/slurm_logs/%j.FastQC.err   # CHANGE ME: stderr log

# ============================================================================
# USER CONFIG - edit these paths for your project
# ============================================================================
# Path to your conda installation's profile script (used to activate envs in batch jobs)
CONDA_PROFILE="/path/to/your/miniconda3/etc/profile.d/conda.sh"

# Conda environment that has fastqc installed (create with: conda create -n fastqc_env -c bioconda fastqc)
CONDA_ENV="fastqc_env"

# Directory holding your raw FASTQ files (script will recursively search this folder)
DATA_DIR="/path/to/your/fastq/files"

# Where FastQC reports (.html + .zip) should be written
OUTDIR="/path/to/your/fastqc_output"

# Suffixes used to identify paired-end reads. Adjust if your files use _1/_2 or .R1./.R2.
R1_SUFFIX="_R1.fastq.gz"
R2_SUFFIX="_R2.fastq.gz"

# ============================================================================
# ACTUAL COMMANDS USING CONFIGS SET ABOVE (MAKES SURE FASTQ.GZ FILES AREN'T CORRUPTED THEN RUNS FASTQC)
# ============================================================================

# The string BANANA is a placeholder. makeScriptsForFastQC.sh uses `sed` to
# replace it with each real sample name when it generates per-sample scripts.
SAMPLE="BANANA"
base="${SAMPLE}"

echo "==> Sample: ${base}"

# Activate the conda env that has fastqc
source "${CONDA_PROFILE}"
conda activate "${CONDA_ENV}"

# Move into the data directory so the relative `find` paths are nice
cd "${DATA_DIR}" || { echo "ERROR: cannot cd to ${DATA_DIR}"; exit 1; }

# Locate R1 and R2 for this sample
input_R1=$(find . -type f -name "${SAMPLE}${R1_SUFFIX}" | head -n 1)
input_R2=$(find . -type f -name "${SAMPLE}${R2_SUFFIX}" | head -n 1)

if [[ -z "$input_R1" || -z "$input_R2" ]]; then
    echo "ERROR: could not find input files for ${SAMPLE}"
    echo "  Looked for: ${SAMPLE}${R1_SUFFIX} and ${SAMPLE}${R2_SUFFIX}"
    exit 1
fi

echo "Found R1: $input_R1"
echo "Found R2: $input_R2"

# Sanity-check that the gzipped files aren't truncated/corrupted before running.
# Catching this here saves you from a confusing FastQC failure later.
for f in "$input_R1" "$input_R2"; do
    if gunzip -t "$f" 2>/dev/null; then
        echo "OK: $f is a valid gzip file."
    else
        echo "ERROR: $f is corrupted or not a valid gzip file."
        exit 1
    fi
done

# Make sure the output directory exists
mkdir -p "$OUTDIR"

echo "==> Running FastQC"

# Skip work that's already done - useful when re-running after a partial failure.
# FastQC names outputs based on the input filename (minus .fastq.gz), so we check
# for the expected .html and .zip pair before running.
r1_name=$(basename "$input_R1" .fastq.gz)
r2_name=$(basename "$input_R2" .fastq.gz)

if [[ -e "${OUTDIR}/${r1_name}_fastqc.html" && -e "${OUTDIR}/${r1_name}_fastqc.zip" ]]; then
    echo "Skipping R1: FastQC output already exists."
else
    fastqc "$input_R1" -o "$OUTDIR"
fi

if [[ -e "${OUTDIR}/${r2_name}_fastqc.html" && -e "${OUTDIR}/${r2_name}_fastqc.zip" ]]; then
    echo "Skipping R2: FastQC output already exists."
else
    fastqc "$input_R2" -o "$OUTDIR"
fi

echo "==> Done with ${base}"
