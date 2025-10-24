# Influence of reference selection

From our previous analyses, we noticed that there wasn't a clear distinction between the used reference and the truth. We argued that this might be because of the read simulation not being to realistically reflect the sequencing errors and biases present in real data (multimodal distrubtion). As most of the time, IGR regions are hard to reconstruct, which was not what we observed in the simulated data.

To overcome this, we decided to use real sequencing data from our own LASV sequencing cohort.


## Data preparation

### Selecting the sample

By going through our results, i selected semi randomly samples that had complete consensus genomes, with not to many Ns, of varying viral loads (Ct values) and not a very high coverage throughout.
LVE00045, LVE00140, LVE00167

![recovery](./images/recovery.png)

![coverage L](./images/coverage_L.png)


### finding similarity

Went to ncbi & downloaded all [available viruses under the name of 'Mammarenavirus Lassaense'](https://www.ncbi.nlm.nih.gov/labs/virus/vssi/#/virus?SeqType_s=Nucleotide&VirusLineage_ss=Mammarenavirus%20lassaense,%20taxid:3052310)
Then for each sequence, I ran mmseqs2 against all other sequences to find similarity values, check [notebook for complete workflow](./00_reference_selection.ipynb)