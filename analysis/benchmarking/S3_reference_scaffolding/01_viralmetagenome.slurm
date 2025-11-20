#!/bin/bash -l
#SBATCH --clusters=wice
#SBATCH --partition=batch_icelake
#SBATCH --account="lp_phylogeo_inf_gpu"
#SBATCH --nodes="1"
#SBATCH --ntasks="2"
#SBATCH --cpus-per-task="36"
#SBATCH --mem-per-cpu="2000M"
#SBATCH --time="72:00:00"
#SBATCH --array=1-133%1

####################################
##### Run a nextflow analysis ######
####################################

#### How to run: ####

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

set -euo pipefail
trap 'abort' 0

# activate the appropriate conda environment
conda activate nf-core

# write some cluster metadata to the error and output files
hostname >&2
echo $0 >&2
printf START >&2; uptime >&2
date >&2

# Define variables
REFERENCE_POOLS_CSV="reference_pools.retry.csv"
SAMPLESHEET_CSV="samplesheet.csv"
TASK_ID=${SLURM_ARRAY_TASK_ID:-1}
LINE_NUMBER=$((TASK_ID + 1))

IFS=',' read -r ID SAMPLE REFERENCE_POOL < <(
    awk -F',' -v line="${LINE_NUMBER}" 'NR==line {print $1","$2","$3}' "${REFERENCE_POOLS_CSV}"
)

OUTDIR="viralmetagenome-out/${SAMPLE}/${ID}"
mkdir -p "${OUTDIR}"

JOB_SAMPLESHEET="viralmetagenome-out/${SAMPLE}/samplesheet.${SAMPLE}.csv"
{ head -n 1 "${SAMPLESHEET_CSV}"; awk -F',' -v sample="${SAMPLE}" 'NR>1 && $1==sample' "${SAMPLESHEET_CSV}"; } > "${JOB_SAMPLESHEET}" || exit 1

if [[ $(wc -l < "${JOB_SAMPLESHEET}") -lt 2 ]]; then
    echo "No samplesheet entry found for sample ${SAMPLE}" >&2
    exit 1
fi

PARAM="params.force.json"
if [[ "${REFERENCE_POOL}" == *"RVDB"* ]]; then
    PARAM="params.noforce.json"
fi

echo "Task ${TASK_ID}: sample=${SAMPLE}, id=${ID}, reference_pool=${REFERENCE_POOL}, PARAM=${PARAM}" >&2
# run the nextflow analysis, when running with tower make sure to have /bin/bash -l to load the .bashrc
# Local config doesn't contain cleanup= true
export NXF_OPTS="-Xms500M -Xmx4G -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
nextflow run Joon-Klaps/viralmetagenome -r force-external-ref-centroid  \
    -ansi-log false \
    -resume \
    -c resources.config \
    -profile singularity \
    -params-file "${PARAM}" \
    --input "${JOB_SAMPLESHEET}" \
    --reference_pool "${REFERENCE_POOL}" \
    --outdir "${OUTDIR}"

# After Nextflow completes, remove all BAM files in the run's output directory to save space
echo "Cleaning up BAM files under ${OUTDIR}..." >&2
# Don't fail the entire job if no files are found or a file cannot be deleted
set +e
BAM_COUNT=$(find "${OUTDIR}" -type f -name "*.bam" | wc -l | tr -d ' ')
if [ "${BAM_COUNT}" -gt 0 ]; then
    # Print the files being deleted for logging, then delete
    find "${OUTDIR}" -type f -name "*.bam" -print -delete
    echo "Deleted ${BAM_COUNT} BAM file(s) in ${OUTDIR}" >&2
else
    echo "No BAM files found in ${OUTDIR}" >&2
fi
set -e

# write some cluster metadata to the error and output files
printf END >&2; uptime >&2

trap : 0

echo >&2 '
************
*** DONE ***
************
'
