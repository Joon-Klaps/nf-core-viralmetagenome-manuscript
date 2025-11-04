nextflow.enable.dsl=2

/*
  nextflow run ./02_determine_GANI.nf -with-conda
*/

params.samplesheet    = "./viralmetagenome-out/combined/contigs_overview.tsv"
params.consensus      = "./viralmetagenome-out/combined/all_consensus.fasta"
params.outdir         = "./data-preparation/global-alignment/"
params.selected_ref   = "./data-preparation/selected-references/selected_references.tsv"
params.references_seq = "./data-preparation/ncbi-virus-fasta/sequences_20251024_LASV.fasta"

include { EXTRACT_SEQ as EXTRACT_REF_SEQ } from './bin/modules.nf'
include { EXTRACT_SEQ as EXTRACT_CONS_SEQ } from './bin/modules.nf'
include { MAFFT_ALIGN } from './bin/modules.nf'
include { ALIGNMENT_STATS } from './bin/modules.nf'
include { CONTIG_SELECTION } from './bin/modules.nf'

workflow {
    // read in combined contig overview
	contig_table = CONTIG_SELECTION(channel.fromPath(params.samplesheet, checkIfExists: true))
	    .splitCsv(header:['index', 'sample', 'segment', 'completeness', 'centroid', 'reference_distance'], skip:1, sep:"\t")
		.map { row ->
			def id = "${row.reference_distance}_${row.index}"
			[[id:id, type:"consensus"]+ row, id]
		}

	selected_refs = Channel.fromPath(params.selected_ref, checkIfExists: true)
		.splitCsv(header:['sample', 'reference', 'fident', 'alnlen', 'mismatch', 'gapopen', 'qstart', 'qend', 'qlen', 'tstart', 'tend', 'tlen', 'evalue', 'bits', 'segment', 'fident_window'], sep:"\t")
		.map { row ->
			def id = "${row.reference}_${row.sample}"
			[[id:id, type:"reference"] + row, row.reference]
		}

	ch_seqs = EXTRACT_CONS_SEQ( contig_table, Channel.fromPath(params.consensus, checkIfExists: true).collect(), ".consensus_ivar")
		.map { meta, seq -> [[meta.segment, meta.sample], meta, seq] }

	ch_refs = EXTRACT_REF_SEQ( selected_refs, Channel.fromPath(params.references_seq, checkIfExists: true).collect(), "")
		.map { meta, seq -> [[meta.segment, meta.sample], meta, seq] }

	// extract sequences for L and S segments if reference_distance contain "RVDB"
	ch_rvdb_cons = ch_seqs
		.filter { _id, meta, _seq -> meta.reference_distance.contains("RVDB")}

	// ch_ref.view{ id, meta, _seq -> "Reference sequence selected: ${id} - ${meta.sample} - ${meta.segment} (ref_distance: ${meta.reference_distance})" }

	ch_seqs_with_ref = ch_seqs
		.mix(ch_refs)
		.combine(ch_rvdb_cons, by: 0)
		.tap {log1}
		.map{ _id, meta, seq, _meta_RVDB, seq_RVDB  -> [meta, seq, seq_RVDB] }

	// log1.view{id, meta, seq, meta_RVDB, seq_RVDB -> "Preparing alignment for: ${id} - ${meta} - ${seq} - ${seq_RVDB})" }


	aln = MAFFT_ALIGN(ch_seqs_with_ref)

	stats = ALIGNMENT_STATS(aln)

	stats.collectFile(keepHeader: true, skip: 1, storeDir: params.outdir){ meta, stats_file ->
		[ "${meta.type}_global_alignment_stats.tsv", stats_file ]
	}

}