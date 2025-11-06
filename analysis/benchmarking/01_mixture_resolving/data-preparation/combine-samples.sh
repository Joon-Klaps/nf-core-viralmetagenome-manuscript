# reads/MN090277.1 reads/MN090188.1
cat reads/MN090277.1_3M_R1.fastq.gz reads/MN090188.1_1M_R1.fastq.gz > combinations/Eddard_R1.fastq.gz
cat reads/MN090277.1_3M_R2.fastq.gz reads/MN090188.1_1M_R2.fastq.gz > combinations/Eddard_R2.fastq.gz

cat reads/MN090277.1_2M_R1.fastq.gz reads/MN090188.1_2M_R1.fastq.gz > combinations/Catelyn_R1.fastq.gz
cat reads/MN090277.1_2M_R2.fastq.gz reads/MN090188.1_2M_R2.fastq.gz > combinations/Catelyn_R2.fastq.gz

cat reads/MN090277.1_1M_R1.fastq.gz reads/MN090188.1_3M_R1.fastq.gz > combinations/Robb_R1.fastq.gz
cat reads/MN090277.1_1M_R2.fastq.gz reads/MN090188.1_3M_R2.fastq.gz > combinations/Robb_R2.fastq.gz

# reads/MN090277.1 reads/MN090240.1
cat reads/MN090277.1_3M_R1.fastq.gz reads/MN090240.1_1M_R1.fastq.gz > combinations/Jon_R1.fastq.gz
cat reads/MN090277.1_3M_R2.fastq.gz reads/MN090240.1_1M_R2.fastq.gz > combinations/Jon_R2.fastq.gz

cat reads/MN090277.1_2M_R1.fastq.gz reads/MN090240.1_2M_R1.fastq.gz > combinations/Sansa_R1.fastq.gz
cat reads/MN090277.1_2M_R2.fastq.gz reads/MN090240.1_2M_R2.fastq.gz > combinations/Sansa_R2.fastq.gz

cat reads/MN090277.1_1M_R1.fastq.gz reads/MN090240.1_3M_R1.fastq.gz > combinations/Arya_R1.fastq.gz
cat reads/MN090277.1_1M_R2.fastq.gz reads/MN090240.1_3M_R2.fastq.gz > combinations/Arya_R2.fastq.gz

# reads/MN090277.1 reads/MZ766668.1
cat reads/MN090277.1_3M_R1.fastq.gz reads/MZ766668.1_1M_R1.fastq.gz > combinations/Daenerys_R1.fastq.gz
cat reads/MN090277.1_3M_R2.fastq.gz reads/MZ766668.1_1M_R2.fastq.gz > combinations/Daenerys_R2.fastq.gz

cat reads/MN090277.1_2M_R1.fastq.gz reads/MZ766668.1_2M_R1.fastq.gz > combinations/Tyrion_R1.fastq.gz
cat reads/MN090277.1_2M_R2.fastq.gz reads/MZ766668.1_2M_R2.fastq.gz > combinations/Tyrion_R2.fastq.gz

cat reads/MN090277.1_1M_R1.fastq.gz reads/MZ766668.1_3M_R1.fastq.gz > combinations/Jaime_R1.fastq.gz
cat reads/MN090277.1_1M_R2.fastq.gz reads/MZ766668.1_3M_R2.fastq.gz > combinations/Jaime_R2.fastq.gz

# All individually:
#     - MN090277.1 100: Bran_R1.fastq.gz, Bran_R2.fastq.gz
#     - MN090188.1 100: Rickon_R1.fastq.gz, Rickon_R2.fastq.gz
#     - MN090240.1 100: Theon_R1.fastq.gz, Theon_R2.fastq.gz
#     - MZ766668.1 100: Jorah_R1.fastq.gz, Jorah_R2.fastq.gz

# Bran
cat reads/MN090277.1_1M_R1.fastq.gz > combinations/Bran_R1.fastq.gz
cat reads/MN090277.1_1M_R2.fastq.gz > combinations/Bran_R2.fastq.gz

# Rickon
cat reads/MN090188.1_1M_R1.fastq.gz > combinations/Rickon_R1.fastq.gz
cat reads/MN090188.1_1M_R2.fastq.gz > combinations/Rickon_R2.fastq.gz

# Theon
cat reads/MN090240.1_1M_R1.fastq.gz > combinations/Theon_R1.fastq.gz
cat reads/MN090240.1_1M_R2.fastq.gz > combinations/Theon_R2.fastq.gz

# Jorah
cat reads/MZ766668.1_1M_R1.fastq.gz > combinations/Jorah_R1.fastq.gz
cat reads/MZ766668.1_1M_R2.fastq.gz > combinations/Jorah_R2.fastq.gz

