#!/bin/bash
###############################################################################
# submitAllScriptsForFastQC.sh - STEP 2 of 2
#
# WHAT THIS SCRIPT DOES
#   Loops over every per-sample script in SCRIPT_DIR and submits it to Slurm
#   with `sbatch`. Slurm queues them up and runs them in parallel as cluster
#   resources become available.
#
# RUN ORDER
#   1) makeScriptsForFastQC.sh        (generates scripts)
#   2) submitAllScriptsForFastQC.sh   <-- you are here
#
# HOW TO USE
#   1) Edit SCRIPT_DIR below to match the one in makeScriptsForFastQC.sh.
#   2) Run on a login node:    bash submitAllScriptsForFastQC.sh
#   3) Monitor your jobs with: squeue -u $USER
###############################################################################

# ============================================================================
# CONFIG
# ============================================================================
# Folder of per-sample scripts to submit. MUST match SCRIPT_DIR in
# makeScriptsForFastQC.sh.
SCRIPT_DIR="/path/to/your/scripts/FastQCscripts"

# Set to "true" to print sbatch commands without actually submitting (useful
# the first time, so you can see what would happen).
DRY_RUN="false"

# ============================================================================
# DO NOT EDIT BELOW THIS LINE
# ============================================================================

cd "$SCRIPT_DIR" || { echo "ERROR: cannot cd to $SCRIPT_DIR"; exit 1; }

shopt -s nullglob  # if no .sh files match, the loop just exits cleanly

submitted=0
for script_file in *.sh; do
    if [ -f "$script_file" ]; then
        if [ "$DRY_RUN" = "true" ]; then
            echo "[DRY RUN] sbatch $script_file"
        else
            echo "Submitting $script_file to Slurm..."
            sbatch "$script_file"
        fi
        submitted=$((submitted+1))
    fi
done

echo "Total scripts processed: $submitted"
echo "Check status with:    squeue -u \$USER"
echo "Cancel all your jobs: scancel -u \$USER  (use carefully!)"
