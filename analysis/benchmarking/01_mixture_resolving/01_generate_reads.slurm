#!/bin/bash -l
#SBATCH --job-name=generate_reads
#SBATCH --array=0-37
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=simulated-reads/logs/generate_reads_%A_%a.out
#SBATCH --error=simulated-reads/logs/generate_reads_%A_%a.err

set -euo pipefail

abort()
{
    echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2
    exit 1
}

trap 'abort' 0

# Create output and log directories
mkdir -p simulated-reads simulated-reads/logs truth-references

# Read selected references from TSV
selected_refs="data-preparation/selected_references.tsv"

if [[ ! -f "${selected_refs}" ]]; then
    echo "Error: ${selected_refs} not found" >&2
    exit 1
fi

# Determine which mixture to process (skip header, so add 2)
if [[ -n "${SLURM_ARRAY_TASK_ID:-}" ]]; then
    line_num=$((SLURM_ARRAY_TASK_ID + 2))
else
    echo "SLURM_ARRAY_TASK_ID is not set. Please submit as an array job or export the variable." >&2
    exit 1
fi

# Extract the specific line for this task
mixture_line=$(sed -n "${line_num}p" "${selected_refs}")

if [[ -z "${mixture_line}" ]]; then
    echo "Error: No data found at line ${line_num}" >&2
    exit 1
fi

# Parse the TSV line
IFS=$'\t' read -r id target ref <<< "${mixture_line}"

echo "Processing mixture: ${id} (target: ${target}, ref: ${ref})"

# Build coverage file (50X per sequence)
coverage_file="simulated-reads/logs/${id}_coverage.txt"
cat > "${coverage_file}" <<EOF
${target}	50
${ref}	50
EOF

echo "Coverage file ready: ${coverage_file}"

# Create combined reference FASTA for this mixture
combined_ref="truth-references/${id}.fasta"
target_file="data-preparation/references/${target}.fasta"
ref_file="data-preparation/references/${ref}.fasta"
cat "${ref_file}" "${target_file}" > "${combined_ref}"

echo "Combined reference ready: ${combined_ref}"

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
        --genomes "${combined_ref}" \
        --seed 42 \
        --output "simulated-reads/${id}" \
        --mode kde \
        --coverage_file "${coverage_file}" \
        --cpus 4 \
        --model MiSeq \
        --compress

# write some cluster metadata to the error and output files
printf END >&2; uptime >&2

trap : 0

echo >&2 '
************
*** DONE ***
************
'
