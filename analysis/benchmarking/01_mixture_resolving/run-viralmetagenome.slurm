#!/bin/bash -l
#SBATCH --clusters=wice
#SBATCH --partition=batch_sapphirerapids
#SBATCH --account="lp_phylogeo_inf_gpu"
#SBATCH --mail-type="END,FAIL,TIME_LIMIT"
#SBATCH --mail-user="joon.klaps@kuleuven.be"
#SBATCH --nodes="1"
#SBATCH --ntasks="2"
#SBATCH --cpus-per-task="36"
#SBATCH --mem-per-cpu="2500M"
#SBATCH --time="72:00:00"

####################################
##### Run a nextflow analysis ######
####################################

#### How to run: ####
# sbatch run-viralmetagenome.slurm

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

# activate the appropriate conda environment
conda activate nf-core

# write some cluster metadata to the error and output files
hostname >&2
echo $0 >&2
printf START >&2; uptime >&2
date >&2

# run the nextflow analysis, when running with tower make sure to have /bin/bash -l to load the .bashrc
nextflow run nf-core/viralmetagenome \
    -r 1.0.0 \
    -ansi-log false \
    -with-tower \
    -resume \
    -profile singularity \
    -c ./nextflow.config \
    -params-file ./params.json \
    --input ./samplesheet.csv \
    --outdir pipeline-output \

# write some cluster metadata to the error and output files
printf END >&2; uptime >&2

trap : 0

echo >&2 '
************
*** DONE ***
************
'
