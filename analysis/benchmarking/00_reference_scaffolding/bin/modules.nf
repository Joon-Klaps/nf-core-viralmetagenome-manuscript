process EXTRACT_SEQ {
	tag "${seq_name}"

	input:
	tuple val(meta), val(seq_name)
	path(fasta)
	val suffix

	output:
	tuple val(meta), path("*.fa")

	script:
	def suffix_value = suffix ?: ""
	"""
	set -euo pipefail

	seqtk subseq ${fasta} <(echo "${seq_name}${suffix_value}") > ${seq_name}.fa
	"""
}

process MAFFT_ALIGN {
	tag "${meta.id}"

	publishDir "${params.outdir}/alignments", mode: 'copy'

	input:
	tuple val(meta), val(seq1), path(seq2)

	output:
	tuple val(meta), path("*.aln.fasta.gz")

	script:
	def prefix = meta.id
	"""
	set -euo pipefail

	# Prepare two-sequence input for MAFFT
	cat ${seq1} ${seq2} > input.two.fa

	# Run MAFFT (global alignment for two sequences)
	mafft --adjustdirection input.two.fa | gzip > ${prefix}.aln.fasta.gz
	"""
}


process CONTIG_SELECTION {
	tag "samplesheet_filtering"

	publishDir "${params.outdir}", mode: 'copy'

	conda('conda-forge::pandas=2.3.3')

	input:
	path(table)

	output:
	path("*.subset.tsv")

	script:
	"""
	set -euo pipefail

	filter_contig_table.py \\
		--table ${table} \\
		--out contig.subset.tsv
	"""
}

process ALIGNMENT_STATS {
	tag "${meta.id}"

	input:
	tuple val(meta), path(aln_fasta)

	output:
	tuple val(meta), path("*_stats.tsv")

	script:
	"""
	set -euo pipefail

	compute_alignment_stats.py \\
		--aln ${aln_fasta} \\
		--out ${meta.id}_stats.tsv
	"""
}

