nextflow.enable.dsl=2

/*
  nextflow run ./02_determine_GANI.nf -with-conda
*/

params.consensus      = "./pipeline-output/consensus/seq/it2/all_consensus.fasta"
params.outdir         = "./data-preparation/global-alignment/"
params.references_seq = "./data-preparation/references/references.fa"

include { MAFFT_ALIGN 				      } from '../../bin/modules.nf'
include { ALIGNMENT_STATS 				  } from '../../bin/modules.nf'

workflow {

	got_dict = [
		"Eddard": ["MN090188", "MN090277"],
		"Catelyn": ["MN090188", "MN090277"],
		"Robb": ["MN090188", "MN090277"],
		"Jon": ["MN090240", "MN090277"],
		"Sansa": ["MN090240", "MN090277"],
		"Arya": ["MN090240", "MN090277"],
		"Daenerys": ["MZ766668", "MN090277"],
		"Tyrion": ["MZ766668", "MN090277"],
		"Jaime": ["MZ766668", "MN090277"],
		"Bran": ["MN090277"],
		"Rickon": ["MN090188"],
		"Theon": ["MN090240"],
		"Jorah": ["MZ766668"]
	]

	ch_ref = channel.fromPath(params.references_seq, checkIfExists: true)
		.splitFasta(record: [id:true, sequence:true])
		.collectFile{ record -> [record.id, ">${record.id}\n${record.sequence}"] }
		.map{ file -> [ [id: file.baseName],  file ]}

	ch_seqs = channel.fromPath(params.consensus, checkIfExists: true)
		.splitFasta(record: [id:true, sequence:true])
		.collectFile{ record -> [record.id, ">${record.id}\n${record.sequence}"] }
		.map { file ->
			def id_parts = file.baseName.tokenize("_")
			[ [id: "${id_parts[0]}_${id_parts[1]}", got: id_parts[0] ],  file ]
		}

	ch_seqs_with_ref = ch_seqs
		.flatMap { meta, seq_file ->
			def refs = got_dict[meta.got] ?: []
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