nextflow.enable.dsl=2

/*
  Pairwise reference pooling and MAFFT alignment pipeline

  Inputs (params):
	- samplesheet: CSV with columns: id,sample,sequence,segment
	- truth_L: directory containing L-segment FASTA files
	- truth_S: directory containing S-segment FASTA files
	- outdir: output directory (default: results)

  For each sample, and per segment (L/S), we:
	1) Resolve each row's sequence to a file under the matching truth dir (by basename)
	2) Generate all unique pairwise combinations of sequences for that sample+segment
	3) Concatenate each pair and run MAFFT to produce a two-sequence alignment
	4) Compute summary statistics for each alignment (matches/mismatches/gaps/Ns)
	5) Merge all per-pair TSVs into a single summary

  Notes:
	- Rows with segment other than L or S (e.g. NA) are ignored
	- Files not found in the truth directory are skipped with a warning
	- Requires MAFFT in PATH (or via conda) and Python3 for stats
*/

params.samplesheet = params.samplesheet ?: "reference_pools.csv"
params.seq_L       = params.seq_L       ?: "./data-preparation/consensus/LASV_L.fasta"
params.seq_S       = params.seq_S       ?: "./data-preparation/consensus/LASV_S.fasta"
params.outdir      = params.outdir      ?: "./data-preparation/global-alignment/"

/* Utility helpers moved inline below to avoid extra modules */

workflow {

	l_seq = channel.fromPath(params.seq_L, checkIfExists: true)
        .splitFasta(record: [id: true, seqString: true])
        .map{ record -> [[sample: record.id, seg:"L"], record.seqString] }

	s_seq = channel.fromPath(params.seq_S, checkIfExists: true)
        .splitFasta(record: [id: true, seqString: true])
        .map{ record -> [[sample: record.id, seg:"S"], record.seqString] }

    // Combine L and S segments into a single channel
    seqs = l_seq.mix(s_seq)

    // read in combined contig overview
	contig_table = channel.fromPath(params.samplesheet)



    seq_ref = seqs.combine(refs, by: 0)
        .map{ meta, seq_flat, id, seq2 -> [meta + [id:id], seq_flat, seq2]}

	MAFFT_out = MAFFT_ALIGN(seq_ref)

}

process MAFFT_ALIGN {
	tag "${meta.id}"

	publishDir "${params.outdir}/alignments", mode: 'copy'

	// Enable one of the environments below as needed
	conda ("bioconda::mafft=7.526")

	input:
	tuple val(meta), val(seq1_flat), path(seq2)

	output:
	tuple val(meta), path("*.aln.fasta.gz")

	script:
	def prefix = meta.id
	"""
	set -euo pipefail

	# Prepare two-sequence input for MAFFT
	{ echo -e ">${meta.sample}_${meta.seg}\n${seq1_flat}"; cat "${seq2}"; } > input.two.fa

	# Run MAFFT (global alignment for two sequences)
	mafft --adjustdirection input.two.fa | gzip > ${prefix}.aln.fasta.gz
	"""
}


process CONTIG_SELECTION {
	tag "samplesheet_filtering"

	publishDir "${params.outdir}", mode: 'copy'

	conda ("conda::python=3.9")

	input:
	path(table)

	output:
	path("*.subset.tsv")

	script:
	"""
	set -euo pipefail

	python filter_contig_table.py \\
		--table ${table} \\
		--out subset.tsv
	"""
}

process ALIGNMENT_STATS {
	tag "${meta.id}"

	publishDir "${params.outdir}/alignment_stats", mode: 'copy'

	conda ("conda::python=3.9")

	input:
	tuple val(meta), path(aln_fasta)

	output:
	path("*_stats.tsv")

	script:
	"""
	set -euo pipefail

	python compute_alignment_stats.py \\
		--aln ${aln_fasta} \\
		--out ${meta.id}_stats.tsv
	"""
}

