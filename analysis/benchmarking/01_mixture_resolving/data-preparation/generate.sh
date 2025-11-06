#!/bin/bash

# Check if the CSV file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_samplesheet.csv>"
    exit 1
fi

# CSV file path
csv_file="$1"

# Create output directory
mkdir -p reads

tail -n +2 "$csv_file" | while IFS=',' read -r sample seed n_reads fasta
do

    echo "Processing sample: $sample with $n_reads reads"

    # Run iss generate command
    iss generate \
        --genomes "$fasta" \
        --seed "$seed" \
        --output "reads/${sample}_${n_reads}" \
        --n_reads "$n_reads" \
        --mode 'kde' \
        --abundance 'lognormal' \
        --cpus 8 \
        --model 'MiSeq' \
        --compress

    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "Successfully generated reads for $sample with $n_reads reads"
    else
        echo "Error generating reads for $sample with $n_reads reads"
    fi

    echo "----------------------------------------"
done

echo "All samples processed"