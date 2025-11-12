# Resolving genome mixtures

This setup was used to see the detection sensitivity of viralmetagenome on mixtures of viral genomes.

## References:

HIV as a an example, easily lot of variation in the genome.
Need to make 3 different categories:

- Little difference : >98% ANI
- Middle difference: 98% > ANI > 90%
- Large difference: 90% > ANI > 80%

> Went to NCBI virus & selected for the following:
>
> - HIV-1 taxid: 11676
> - \# Ambiguous characters < 10
> - Complete nucleotide sequences

Sequences had their ANI reported with `mmseqs-easysearch`:

```bash
mmseqs easy-search complete.fasta complete.fasta run1.m8 tmp -s 7 --search-type 3 --format-output query,target,theader,fident,qlen,tlen,alnlen,mismatch,gapopen,qstart,qend,tstart,tend,evalue,bits
```

Selecting the different categories:

```bash
awk -F"\t" '{if ($4 > 0.98) print $0}' run1.m8 > 98.txt
awk -F"\t" '{if ($4 <= 0.98 && $4 > 0.90) print $0}' run1.m8 > 90.txt
awk -F"\t" '{if ($4 <= 0.90 && $4 > 0.80) print $0}' run1.m8 > 80.txt
```

Selecting only 4 genomes that satisfy the condition, where a single genome occurs in all 3 files:

- Selecting a random genome: MN090277.1

> [!Note] "100-98"
> MN090277.1 MN090188.1 MN090188.1 |HIV-1 isolate 9242_wk12_10_C2 from USA, complete genome|Human immunodeficiency virus 1|USA|complete|9056 0.987 9232 9056 166 2 0 166 1 14 179 2.068E-77 290

> [!Note] "90-98"
> MN090277.1 MN090240.1 MN090240.1 |HIV-1 isolate 9242_W12_6L24_S323 from USA, complete genome|Human immunodeficiency virus 1|USA|complete|9015 0.967 9232 9015 9000 297 0 169 9168 1 8993 0.000E+00 14808

> [!Note] "80-98"
> MN090277.1 MZ766668.1 MZ766668.1 |HIV-1 isolate 074-AP-138-1-4_w0_210 from Botswana, complete genome|Human immunodeficiency virus 1|Botswana|complete|9011 0.835 9232 9011 9031 1482 0 165 9195 27 9011 0.000E+00 9570

So the selected genomes are:

- MN090277.1
- MN090188.1
- MN090240.1
- MZ766668.1

getting the sequences:

```bash
esearch -db nuccore -query "MN090277.1" | efetch -format fasta > MN090277.1.fasta
esearch -db nuccore -query "MN090188.1" | efetch -format fasta > MN090188.1.fasta
esearch -db nuccore -query "MN090240.1" | efetch -format fasta > MN090240.1.fasta
esearch -db nuccore -query "MZ766668.1" | efetch -format fasta > MZ766668.1.fasta
```

## Read generation

To create the different variations in read abundance, thinking it will be best if we let the tool decide the number of reads and not subsample ourselves downwards.

So we have made for all four genomes 3 different read sets:

- 1M
- 2M
- 3M
  using `iss generate` with the following arguments: `--mode 'kde' --abundance 'lognormal' --model 'MiSeq'`.

Next, we need to make combinations of the reads together, we always get to 4M reads in total:

- MN090277.1-MN090188.1
  - 75-25: Eddard_R1.fastq.gz, Eddard_R2.fastq.gz
  - 50-50: Catelyn_R1.fastq.gz, Catelyn_R2.fastq.gz
  - 25-75: Robb_R1.fastq.gz, Robb_R2.fastq.gz
- MN090277.1-MN090240.1
  - 75-25: Jon_R1.fastq.gz, Jon_R2.fastq.gz
  - 50-50: Sansa_R1.fastq.gz, Sansa_R2.fastq.gz
  - 25-75: Arya_R1.fastq.gz, Arya_R2.fastq.gz
- MN090277.1-MZ766668.1
  - 75-25: Daenerys_R1.fastq.gz, Daenerys_R2.fastq.gz
  - 50-50: Tyrion_R1.fastq.gz, Tyrion_R2.fastq.gz
  - 25-75: Jaime_R1.fastq.gz, Jaime_R2.fastq.gz
- All individually:
  - MN090277.1 100: Bran_R1.fastq.gz, Bran_R2.fastq.gz
  - MN090188.1 100: Rickon_R1.fastq.gz, Rickon_R2.fastq.gz
  - MN090240.1 100: Theon_R1.fastq.gz, Theon_R2.fastq.gz
  - MZ766668.1 100: Jorah_R1.fastq.gz, Jorah_R2.fastq.gz
