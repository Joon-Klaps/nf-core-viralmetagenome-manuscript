Reviewer 1:

Well done on creating this fantastic well documented pipeline. I have a few recommendations:

We thank the reviewer for these kind words.

1. The documentation at https://nf-co.re/viralmetagenome/dev/ says that bowtie2 is used to perform host removal. But the figure in the manuscript identifies kraken2 for host removal. In addition, the manuscript says kraken2 is used for host removal. Please correct either the documentation or the paper.

Due to community demand, we included both kraken2 and bowtie2 for decontamination. We have updated the documentation on the code repository and the manuscript. Kraken2 and Bowtie2 are both available for decontamination.

2. Step 12 "Annotate 0-depth regions with external reference" should never exist. During the covid pandemic some labs were submitting sequences with the reference injected into the sequence. This caused all sorts of problems. I strongly recommend removing this step completely.

We agree with the Reviewer’s suggestion. Both reviewers have raised concerns with this approach, given the lack of support for improved accuracy by annotating the scaffold with the reference genome, we have decided to deprecate this functionality of the pipeline. Within the current version (v1.0.0) and any future versions, this functionality will no longer be supported, and scaffolds with ambiguous regions will keep their ambiguous regions. .

3. It's unclear to me what "variant calling" is used for or why it's performed. From reading the documentation, variant calling is done for detecting minority variants. I recommend adding a sentence to clarify why variant calling is performed and to clarify it's not for polishing.

That’s a great suggestion, we determine minor variants in the sense of true minor variants as variants are called not towards an external reference but towards the consensus itself. Additionally, in order to call consensus with bcftools (one of the two options, alternative option is Ivar), a variant file is required. Hence, during polishing, when the tool bcftools is used, variants are still called but as intermediate results.


4. Why is deduplication of reads (step 15) performed? The diagram presents this step as a dead end, are the reads deduped then variant calling performed?

After deduplication, variants and consensus are called, so this is not a dead end. On the diagram the dead end is determining mapping statistics. The statistics determined on the mapped reads, are descriptive, this is way it’s a dead-end. To clarify this, we have updated the readme.md file on github mentioning that mapped reads are optionally deduplicated and that users can optionally determine various mapping statistic, see commit: https://github.com/nf-core/viralmetagenome/pull/212/commits/6bb246a809dbcb9f1d1583fc25ec62c61cb200c9.


5. Can you please expand on the iterative consensus refinement step. Why is it performed and what is the process.

Iterative consensus refinement is performed to reduce reference bias and improve consensus accuracy by repeatedly mapping reads towards the current consensus, calling variants, and applying those variants to produce an updated reference that better reflects the sample sequence.
More specifically, (1) the process starts from a de novo scaffold, (2) reads are mapped to the current reference (BWA‑MEM2 by default, or BWA / bowtie2), (3) optional deduplication (Picard or UMI‑tools for UMI libraries) and mapping statistics collection are performed, (4) variants are called (iVar or BCFtools) and subjected to configurable filtering (example defaults used in the pipeline: SNP depth ≥10 and base quality ≥20), (5) filtered variants are applied to generate an updated consensus (bcftools consensus or iVar consensus) which becomes the reference for the next cycle, and (6) the cycle repeats (default 2 iterations, configurable up to 4) until the configured number of iterations is reached (users may also check convergence by comparing consecutive FASTAs).
Reviewer 2:
The authors present a novel analysis nf-core workflow for viral metagenomics called viralmetagenome. The use of nextflow and integration into the nextflow-core framework gives it great potential for support and reproducibility.
Altogether the authors have made a great effort to create a “core” workflow for viral metagenomics. However, the many seemingly redundant optional tools, in the workflow with little explanation about their pro’s and con’s make it difficult to see what the “core” workflow is making it more a of an aggregation of many possible tools. This limits the great potential for having a go-to recommended workflow.
The availability of different tools allows the pipeline to cover many edge cases and maximises it’s use. The what can be perceived as redundant optional tools serve the important purpose of user-preference.
The “multi-assembler approaches” seems interesting and it seems a good approach to use the so-called “wisdom of the crowds” but how this done is not well described. How are the results of multiple assemblers combined/used in a multi-assembler approach?
We run multiple assemblers (by default SPAdes, MEGAHIT) to leverage complementary strengths. In summary, the output contigs of both tools are just concatenated. However, this introduces redudancy and not all contigs are relevant or in other words, of the viral strains of interest. To overcome this, we identify a series of scaffolding reference candidates through a blast search on all contigs followed by contig clustering. After clustering, the contigs are scaffolded towards the identified reference, if no reference was identified, the contigs are scaffolded against the longest contig.
A hallmark of a good analysis workflow is a good reference database (curated for good specificity or large non-curated for good sensitivity), why are the authors using an outdated database Reference Viral Database (RVDB) from a manuscript from 2018? I am unable to find this database online via the links in the manuscript, and the GitHub page has not been updated in 7 years. This would miss SARS-CoV-2 for instance. Similarly, Virosaurus is a database that has not been updated since 2020, can the authors explain the choice for this database?
We agree that good reference databases are crucial for reliable outcomes. The Reference Viral Database is updated biannually, the unmaintained github repository the reviewer is referring to is merely the code used to pull records and to cluster them. The database is available at https://rvdb.dbi.udel.edu/, and has, at the time of writing, its latest release on June 6th 2025. It is currently just short of 6 million SARS-CoV-2 records.
To our knowledge, virousaurus is the only easily accessible and curated dataset that has an elaborate viral sequence with metadata annotation. For this reason, virosaurus is only used to annotate the final consensus sequences with metadata, for example, species, segment, suspected host. If no significant hits are identified, no metadata annotation to the final consensus genomes is provided.



Taxonomic annotation is performed by Kraken2 and Kaiju on the reads, and BlastN and again Kraken2 and Kaiju on the contigs. It is unclear what reference database were used, and why BlastN was not sufficient?

During polishing, blastN and the taxonomic classifiers (Kaiju and Kraken2) don’t serve the same purpose. blastN is used to identify potential references for scaffolding. Kaiju and Kraken2 are being used to cluster the contigs and the identified references.

The authors give multiple options for clustering the contigs, why were these options for clustering chosen and, as a user, how would I decide what clustering algorithm to use, is one used as default, and why?
The default contig clustering algorithm, ‘cd-hit-est’, is a long-standing tool for contig clustering. For this reason, it’s been the default. The MMseqs framework is a new and popular tool that provides a lot of flexibility, thats why we included it. The others, are there for user preference.

The same goes for the read mapping, as a core workflow, I would expect benchmark supported best standard choices, not multiple options without guidance of which to use.

We agree with the reviewer that it should be clear to the user that the tools selected should comply with their needs. For the mappers, we agree that BWA-MEM is redundant given that BWA-MEM2 is also available. BWA-mem2 is the default mapper for variant calling and consensus generation due to their higher variant detection rate (Yao et al, 2020; https://doi.org/10.1186/s12859-020-03704-1). However, given the high overall abundance of Bowtie2 as a short read mapper in microbial metagenomic pipelines, we also provide the opportunity for users to switch to Bowtie2, depending on their preference.


For the consensus generation the authors indicate that: “Regions with zero coverage depth can optionally be represented by the reference genome to produce a more complete scaffold genome for consensus calling.” I do not understand zero coverage can be the result if the reference is the representative contig in a cluster, that would mean that there would at least be 1x coverage. In addition, filling in consensus sequences with the reference when there is too little coverage is a very bad practice, and it would be questionable to have an nf-core pipeline recommend this practice as this will create consensus sequence with over-confidence about their completeness/correctness. The better practice alternative is keeping separate contigs or filling in with “N”.

The reviewer raises a valid point. Given the lack of support for improved accuracy by annotating the scaffold with the reference genome, we have decided to deprecate this functionality of the pipeline. Within the current version (v1.0.0) and any future versions, this functionality will no longer be supported, and scaffolds with ambiguous regions will keep their ambiguous regions.

About the benchmarking:
What options were used out of all the options the workflow offers?

It would be great to see some more results from the HIV-1 benchmark, Figure 1 from S1 shows mismatches, nucleotide identity, and number of Ns when using different references, but what does that mean? I would like to know what the performance is of the workflow, which reference genome did it pick and if the authors would have picked a reference by hand how would it have performed compared to the automated analysis? And also, what impact would that have on the downstream interpretation of the data. Missing a crucial mutation in HIV-1 could be detrimental.

Looking at the benchmark with real datasets, 79GB RAM would not allow the workflow to run on a local desktop as is indicated in the introduction. Also, what do the authors mean by “excluding taxonomic classification steps” how did the workflow work without them?

“The automated reference selection offers substantial improvements over manual curation by reducing processing time while preserving reconstruction accuracy” – Where did the authors compare the outputs to manual curation?

“Performance correlates strongly with reference database comprehensiveness, as consensus genomes tended to be more complete and similar to the true consensus sequence when the scaffolding reference was closer to the true viral genome.” – Did the authors run the workflow with different reference databases, to come to this conclusion?

“This emphasizes the need to keep databases like RVDB (Goodacre et al. 2018) and Virosaurus (Gleizes et al. 2020) up-to-date.” – I find this a strange remark, I would suggest to use another database, one which has been recently updated, or recommend how to curate your own reference database from Genbank for instance. Especially since the authors conclude that “Performance correlates strongly with reference database comprehensiveness, as consensus genomes tended to be more complete and similar to the true consensus sequence”
As mentioned in the previous comment, the RVDB is updated biannually and is therefore very much up to date. Within the online documentation, there is a guide on how to create your own annotation and reference database: https://nf-co.re/viralmetagenome/dev/docs/usage/databases.
The results and description of the benchmarking of the workflow also too limited for me to judge what “version” of the workflow the authors ran and how it performed, making it impossible to judge if this is a good “core” workflow.

Some remarks about the nf-core webpage:
On the usage page the installation instructions is a dead link.
The flowchart on the nf-core page is not the same as the flowchart in the manuscript. Also naming the workflow “viralgenie” and “virametagenome” in different places is confusing.
I’m getting an error when running the test command: ERROR ~ No such file or directory: https://github.com/Joon-Klaps/viralgenie/blob/dev/docs/images/ViralGenie-nf-core-theme.png
Could the authors please fix the test suite, and perhaps test the workflow on another dataset, to make sure that it runs without errors as I would like to test it with some of my own data, for which I know what results to expect.
All these comments were related to nextflow itself, and the webpage of nf-core defaulting to the ‘master’ branch. After nf-coreviralmetagenome’s initial release, the test-suite and documentation have been updated.
There are multiple GitHub issues still open, I would recommend addressing
Github issues relating to bugs have been closes. Suggested enhancements are still open, it’s common to have multiple issues open, it allows end-users to engage in ongoing discussions.  th
ese before publication.
