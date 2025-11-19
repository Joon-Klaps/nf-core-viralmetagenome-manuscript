nextflow.enable.dsl=2

/*
  nextflow run ./02_determine_GANI.nf -with-conda
*/

params.consensus      = "./pipeline-output/consensus/seq/it2/*/*.fasta"
params.outdir         = "./data-preparation/global-alignment/"
params.references_seq = "./data-preparation/references/*.fasta"

include { MAFFT_ALIGN 				      } from '../../bin/modules.nf'
include { ALIGNMENT_STATS 				  } from '../../bin/modules.nf'

workflow {

	ch_ref = channel.fromPath(params.references_seq, checkIfExists: true)
		.map{ file -> [ [id: file.baseName.tokenize(".")[0]],  file ]}

	ch_seqs = channel.fromPath(params.consensus, checkIfExists: true)
		.map { file ->
			def id_parts = file.baseName.tokenize("_")
			[ [id: "${id_parts[0]}_${id_parts[1]}", refs: [id_parts[0].tokenize(".")[0], "MN090277" ]],  file ]
		}

	ch_seqs_with_ref = ch_seqs
		.flatMap { meta, seq_file ->
			def refs = meta.refs ?: []
			return refs.collect { ref_id ->
				[meta, ref_id, seq_file]
			}
		}
		.combine(ch_ref)
		.tap{log1}
		.filter { _meta, ref_id, _seq_file, ref_meta, _ref_file ->
			ref_meta.id == ref_id
		}
		.map { meta, ref_id, seq_file, _ref_meta, ref_file ->
			[ meta + [id: "${meta.id}_${ref_id}", reference:ref_id], seq_file, ref_file ]
		}

	// log1.view()
	// ch_seqs_with_ref.view()

	aln = MAFFT_ALIGN(ch_seqs_with_ref)

	stats = ALIGNMENT_STATS(aln)

	stats.collectFile(keepHeader: true, skip: 1, storeDir: params.outdir){ meta, stats_file ->
		[ "global_alignment_stats.tsv", stats_file ]
	}

}