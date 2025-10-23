#!/bin/bash -l
#SBATCH --clusters=genius
#SBATCH --partition=gpu_p100
#SBATCH --account="lp_phylogeo_inf_gpu"
#SBATCH --job-name=generate_reads
#SBATCH --time=02:00:00
#SBATCH --nodes="1"
#SBATCH --gpus-per-node="1"
#SBATCH --cpus-per-gpu="9"
#SBATCH --mem-per-cpu="2000M"
#SBATCH --output=simulated-reads/logs/generate_reads_%A_%a.out
#SBATCH --error=simulated-reads/logs/generate_reads_%A_%a.err

set -euo pipefail

# Create output and log directories
mkdir -p simulated-reads simulated-reads/logs

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
        --genomes truth-references/*.fasta \
        --seed 42 \
        --output "simulated-reads/" \
        --mode kde \
        --abundance lognormal \
        --cpus 1 \
        --model MiSeq \
        --compress

echo "Completed processing for ${current_species}"