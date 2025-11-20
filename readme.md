# Supplementary Data for nf-core/viralmetagenome Manuscript


## S1. Sample mixture resolution

We evaluated the pipeline's resolution sensitivity across a continuous spectrum of genetic diversity by simulating HIV-1 coinfections. We identified three distinct performance zones based on empirical ANI thresholds: Unresolved Zone, Interference Zone, and High-Fidelity Resolution.

**Supplementary Figure 1:** Mixture resolution dynamics across a genetic diversity gradient.

For more details and scripts, see [analysis/benchmarking/S1_mixture_resolving/](analysis/benchmarking/S1_mixture_resolving/).

## S2. Evaluation of nf-core/viralmetagenome on public data

We constructed a public metagenomic dataset targeting various human and plant viruses to evaluate the pipeline's performance on real-world data. Samples were processed using `nf-core/viralmetagenome` with specific parameters for clustering and database selection.

For more details and scripts, see [analysis/benchmarking/S2_performance_on_public_data/](analysis/benchmarking/S2_performance_on_public_data/).

## S3. Influence of scaffolding reference

We investigated the influence of scaffolding references on consensus genome completeness using a subset of LASV samples. We compared consensus genomes generated with different scaffolding references spanning a range of nucleotide similarities to determine the impact on genome reconstruction quality.

**Supplementary Figure 2:** Jitter-boxplot for scaffolding reference genomes considered in the sample setup for determining the influence of the scaffolding reference.

For more details and scripts, see [analysis/benchmarking/S3_reference_scaffolding/](analysis/benchmarking/S3_reference_scaffolding/).

## Compile latex

```bash
make all
```