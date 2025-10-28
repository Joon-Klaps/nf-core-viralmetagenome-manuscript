nextflow.enable.dsl=2

/*
  nextflow run ./02_determine_GANI.nf -with-conda
*/

params.samplesheet = "./viralmetagenome-out/combined/contigs_overview.tsv"
params.seq_L       = "./data-preparation/consensus/LASV_L.fasta"
params.seq_S       = "./data-preparation/consensus/LASV_S.fasta"
params.consensus   = "./viralmetagenome-out/combined/all_consensus.fasta"
params.outdir      = "./data-preparation/global-alignment/"

workflow {
    // read in combined contig overview
	contig_table = CONTIG_SELECTION(channel.fromPath(params.samplesheet, checkIfExists: true))
	    .splitCsv(header:['index', 'sample', 'segment', 'completeness', 'centroid', 'reference_distance'], skip:1, sep:"\t")
		.map { row ->
			def id = "${row.reference_distance}_${row.index}"
			[[id:id]+ row, id]
		}

	EXTRACT_SEQ( contig_table, Channel.fromPath(params.consensus, checkIfExists: true).collect())
		.combine(channel.fromPath(params.seq_L, checkIfExists: true))
		.combine(channel.fromPath(params.seq_S, checkIfExists: true))
		.branch { meta, seq, L, S ->
			l : meta.segment == "L"
				return [meta, seq, L]
			s : meta.segment == "S"
				return [meta, seq, S]
		}.set { ch_seqs_by_segment }

	mafft_in = ch_seqs_by_segment.l.mix( ch_seqs_by_segment.s )

	aln = MAFFT_ALIGN(mafft_in)

	stats = ALIGNMENT_STATS(aln)

	stats.collectFile(keepHeader:true, skip:1, storeDir: params.outdir, name: "combined_alignment_stats.tsv")

}

process EXTRACT_SEQ {
	tag "${seq_name}"

	input:
	tuple val(meta), val(seq_name)
	path(fasta)

	output:
	tuple val(meta), path("*.fa")

	script:
	"""
	set -euo pipefail

	seqtk subseq ${fasta} <(echo "${seq_name}.consensus_bcftools") > ${seq_name}.fa
	"""
}

process MAFFT_ALIGN {
	tag "${meta.id}"

	publishDir "${params.outdir}/alignments", mode: 'copy'

	input:
	tuple val(meta), val(seq1), path(seq2_file)

	output:
	tuple val(meta), path("*.aln.fasta.gz")

	script:
	def prefix = meta.id
	"""
	set -euo pipefail

	# Prepare two-sequence input for MAFFT
	{ cat ${seq1}; seqtk subseq "${seq2_file}" <(echo "${meta.sample}_${meta.segment}"); } > input.two.fa

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
	path("*_stats.tsv")

	script:
	"""
	set -euo pipefail

	compute_alignment_stats.py \\
		--aln ${aln_fasta} \\
		--out ${meta.id}_stats.tsv
	"""
}

