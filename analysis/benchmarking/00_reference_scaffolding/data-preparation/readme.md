Went to NCBI virus.

[Selected Nucleotide_completeness: complete](https://www.ncbi.nlm.nih.gov/labs/virus/vssi/#/virus?SeqType_s=Nucleotide&Completeness_s=complete)

Then I selected the following viruses:

- Orthonairovirus haemorrhagiae
- Mammarenavirus lassaense
- Zika virus
- West Nile virus
- Human immunodeficiency virus 1
- Monkeypox virus
- Influenza A virus
- Severe acute respiratory syndrome coronavirus 2
- Human respiratory syncytial virus A
- Ebola virus

Downloaded either all sequences or a random subset of 2000 sequences (if more than 2k available). Downloaded in FASTA format with Accession, GenBank, Segment headers.

Next for each species segment combination I chose a representative sequence, and searched against all other sequences of the same species using mmseqs2. From these results, I selected a set of references that cover a range of sequence identities to the representative sequence (in 2% windows from 80% to 100% identity). These selected references were used for the reference-based scaffolding benchmarking.