# Supplementary data for the nf-core/viralmetagenome manuscript

Scripts, parameters and results of the validation and benchmarking analyses in *nf-core/viralmetagenome: a novel pipeline for untargeted viral genome reconstruction* (Klaps *et al.*, Bioinformatics 2026, [10.1093/bioinformatics/btag187](https://doi.org/10.1093/bioinformatics/btag187)), which is also Chapter 3 of the PhD thesis of Joon Klaps (KU Leuven, 2026). The manuscript and supplementary methods are in LaTeX in this repository.

## Where to find the pipeline

- Source code: [github.com/nf-core/viralmetagenome](https://github.com/nf-core/viralmetagenome) (MIT licence)
- Documentation: [nf-co.re/viralmetagenome](https://nf-co.re/viralmetagenome), with [usage](https://nf-co.re/viralmetagenome/docs/usage) and a description of [every output file](https://nf-co.re/viralmetagenome/docs/output)
- Example output of the full-size test: [nf-co.re/viralmetagenome/results](https://nf-co.re/viralmetagenome/results)
- Archive of every release: [doi.org/10.5281/zenodo.17524074](https://doi.org/10.5281/zenodo.17524074) (each release has its own DOI)
- Try it on a minimal dataset: `nextflow run nf-core/viralmetagenome -profile test,docker --outdir results`

The analyses below ran on a development build of the pipeline (`v1.0.0-g0430440`, June 2025), a few months before release 1.0.0. The forced-reference experiment in S3 ran on [this modified version](https://github.com/Joon-Klaps/viralmetagenome/releases/tag/v1.0.0-force-external-centroid). Rerun them with a release from the archive above and expect small differences.

## Layout

| Path | Content |
|---|---|
| `analysis/benchmarking/S1_performance_on_public_data/` | Public human and plant virus metagenomes, with the pipeline output and MultiQC reports |
| `analysis/benchmarking/S2_mixture_resolving/` | Simulated HIV-1 co-infections, with the scripts that simulate the reads, run the pipeline and score the result |
| `analysis/benchmarking/S3_reference_scaffolding/` | Lassa virus samples assembled with scaffolding references of falling similarity, with the notebooks and parameter files of both runs (`params.force.json`, `params.noforce.json`) |
| `Fig/` | Figures of the manuscript |
| `manuscript-*.tex`, `supplementary-methods*.tex` | Manuscript sources (the `*-old` and `*-diff` files are earlier versions) |

The scripts and notebooks of S2 and S3 are numbered in the order they run. The reads of S2 are simulated. The Lassa virus consensus genomes in S3 and the Ct values of their samples are included, and the raw reads are not.

## S1. Evaluation of nf-core/viralmetagenome on public data

We constructed a public metagenomic dataset targeting various human and plant viruses to evaluate the pipeline's performance on real-world data. Samples were processed using `nf-core/viralmetagenome` with specific parameters for clustering and database selection.

For more details and scripts, see [analysis/benchmarking/S1_performance_on_public_data/](analysis/benchmarking/S1_performance_on_public_data/).

## S2. Sample mixture resolution

We evaluated the pipeline's resolution sensitivity across a continuous spectrum of genetic diversity by simulating HIV-1 co-infections. We identified three distinct performance zones based on empirical ANI thresholds: Unresolved Zone, Interference Zone, and High-Fidelity Resolution.

**Supplementary Figure 1:** Mixture resolution dynamics across a genetic diversity gradient.

For more details and scripts, see [analysis/benchmarking/S2_mixture_resolving/](analysis/benchmarking/S2_mixture_resolving/).


## S3. Influence of scaffolding reference

We investigated the influence of scaffolding references on consensus genome completeness using a subset of LASV samples. We compared consensus genomes generated with different scaffolding references spanning a range of nucleotide similarities to determine the impact on genome reconstruction quality.

**Supplementary Figure 2:** Jitter-boxplot for scaffolding reference genomes considered in the sample setup for determining the influence of the scaffolding reference.

For more details and scripts, see [analysis/benchmarking/S3_reference_scaffolding/](analysis/benchmarking/S3_reference_scaffolding/).

## Compile latex

```bash
make all
```