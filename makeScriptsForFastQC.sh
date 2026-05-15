#!/bin/bash
###############################################################################
# makeScriptsForFastQC.sh - STEP 1 of 2
#
# WHAT THIS SCRIPT DOES
#   Scans DATA_DIR for *_R1.fastq.gz files, extracts each sample name, then
#   generates one per-sample Slurm script in SCRIPT_DIR by copying the base
#   template (FastQC.sh) and using `sed` to replace the BANANA placeholder
#   with the real sample name.
#
# RUN ORDER
#   1) makeScriptsForFastQC.sh   <-- you are here (generates scripts)
#   2) submitAllScriptsForFastQC.sh   (submits all generated scripts)
#
# HOW TO USE
#   1) Edit the CONFIG block below.
#   2) Run on a login node:    bash makeScriptsForFastQC.sh
#   3) Spot-check the generated scripts in SCRIPT_DIR before submitting.
###############################################################################

# ============================================================================
# CONFIG - edit these paths for your project
# ============================================================================
# Directory holding your raw FASTQ files (same as DATA_DIR in FastQC.sh)
DATA_DIR="/path/to/your/fastq/files"

# Full path to your base FastQC.sh template
BASE_SCRIPT="/path/to/your/scripts/FastQC.sh"

# Where the generated per-sample scripts should be written.
# Use a dedicated folder - the submit step will run sbatch on every .sh in here.
SCRIPT_DIR="/path/to/your/scripts/FastQCscripts"

# Suffix used to identify R1 files (sample name = filename minus this suffix)
R1_SUFFIX="_R1.fastq.gz"

# ============================================================================
# ACTUAL SCRIPT FOR FASTQC
# ============================================================================

# Make sure the output directory exists
mkdir -p "$SCRIPT_DIR"

# Move into the data directory so the find paths are clean
cd "$DATA_DIR" || { echo "ERROR: cannot cd to $DATA_DIR"; exit 1; }

count=0
find . -type f -name "*${R1_SUFFIX}" | while read -r filepath; do
    # Strip the R1 suffix to get the sample name.
    # e.g. ./subdir/Sample_42_R1.fastq.gz  ->  Sample_42
    sample=$(basename "$filepath" "${R1_SUFFIX}")

    echo "Generating script for sample: $sample"

    # The `sed` step: copy the base script and swap BANANA for the real
    # sample name. The @ is just an alternate delimiter for sed (so paths
    # with / don't confuse it).
    sed "s@BANANA@${sample}@g" "${BASE_SCRIPT}" \
        > "${SCRIPT_DIR}/${sample}.fastqc.sh"

    count=$((count+1))
done

echo "Done. Per-sample scripts live in: ${SCRIPT_DIR}"
echo "Next step: bash submitAllScriptsForFastQC.sh"
