#!/bin/bash -l
#SBATCH --clusters=wice
#SBATCH --account="lp_phylogeo_inf_gpu"
#SBATCH --mail-type="END,FAIL,TIME_LIMIT"
#SBATCH --mail-user="joon.klaps@kuleuven.be"
#SBATCH --partition=batch_sapphirerapids
#SBATCH --ntasks=30
#SBATCH --mem=50000M
#SBATCH --time="24:00:00"

####################################
##### Run a muscle5 analysis ######
####################################

#### How to run: ####
# sbatch --export=ALL,ARGS='' run-fetchngs.slurm

# write a function that catches any errors
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

set -e
trap 'abort' 0

# write some cluster metadata to the error and output files
hostname >&2
echo $0 >&2
printf START >&2; uptime >&2
date >&2

### here my acutal commands start
conda activate nf-core

nextflow run nf-core/fetchngs \
    --input data/sra_selection.csv \
    --outdir data/sra \
    -ansi-log false \
    --nf_core_pipeline viralrecon \
    --download_method sratools \
    -profile singularity

# write some cluster metadata to the error and output files
printf END >&2; uptime >&2

trap : 0

echo >&2 '
************
*** DONE ***
************
'
