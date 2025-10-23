#!/bin/bash -l
#SBATCH --job-name=generate_reads
#SBATCH --array=0-9
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --output=simulated-reads/logs/generate_reads_%A_%a.out
#SBATCH --error=simulated-reads/logs/generate_reads_%A_%a.err

set -euo pipefail

# Create output and log directories
mkdir -p simulated-reads simulated-reads/logs

# Define species array
species=("CCHF" "EBOV" "FLU" "HIV" "LASV" "MPX" "RSV" "SARS2" "WNV" "ZKV")

# Determine which species to process
if [[ -n "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    species_index=${SLURM_ARRAY_TASK_ID}
else
    echo "SLURM_ARRAY_TASK_ID is not set. Please submit as an array job or export the variable." >&2
    exit 1
fi

current_species=${species[$species_index]}

echo "Processing species: ${current_species} (task ${species_index})"

# Build coverage file (20X per reference)
coverage_file="simulated-reads/logs/${current_species}_coverage.txt"
grep '^>' truth-references/*"${current_species}".fasta \
    | cut -d ' ' -f1 \
    | sed 's/.*:>//' \
    | sed 's/^>//' \
    | awk '{print $1"\t20"}' \
    > "${coverage_file}"

if [[ ! -s "${coverage_file}" ]]; then
    echo "Failed to create coverage file at ${coverage_file}" >&2
    exit 1
fi

echo "Coverage file ready: ${coverage_file}"

workdir=$(pwd)
singularity_image="docker://quay.io/biocontainers/insilicoseq:2.0.1--pyh7cba7a3_0"

# Run iss generate command inside the Singularity container
## THERE IS A BUG WITH THE MULTI THREADING OF INSILICOSEQ, SO USING 1 CPU
singularity exec \
    --cleanenv \
    --bind "${workdir}:${workdir}" \
    --pwd "${workdir}" \
    "${singularity_image}" \
    iss generate \
        --genomes truth-references/*"${current_species}".fasta \
        --seed 42 \
        --output "simulated-reads/${current_species}" \
        --mode kde \
        --coverage_file "${coverage_file}" \
        --cpus 1 \
        --model MiSeq \
        --compress

echo "Completed processing for ${current_species}"