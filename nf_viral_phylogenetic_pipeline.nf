def hostname = "hostname".execute().text.trim() // in case we want to overwrite clusterOptions directive for a specific module we still need to "stay" on the same host
ExecutionDir = new File('.').absolutePath

// All defaults are included in a shell wrapper

// input can be one of the following:
// 1. A single FASTA file containing sequences - for single segment viruses like SARS-CoV-2
// 2. A directory containing multiple FASTA files - for multi-segment viruses like Influenza
params.input_dir = ""


metadata = file(params.metadata)
organism = params.organism


params.threshold_Ns = ""
params.threshold_ambiguities = ""
params.map_detail = ""
params.results_dir = ""
params.results_prefix = ""

// Image with main program
params.main_image = ""

// Loaction of modules
params.projectDir = ""
modules = "${params.projectDir}/modules"

// IQ-tree relared parameter
params.model = "" // Model for iq-tree
params.bootstrap = "" // Number of bootstraps for iq-tree
params.min_support = "" // Minimum support for a branch to keep it in a tree
params.starting_trees = "" // Numer of random starting tress

// Timetree parameters
params.clockrate = "" // User can still override any built-ins and values estimated from the alignment
params.skip_clockrate_estimation = "false" // Set by the shell wrapper when all samples share one sampling date

// Maximal number of CPUS allocated to a module
params.threads = ""

src_dir = "${baseDir}/src"

// Pipeline is executed with violated safegurads levels (e.g. samples from viruses from different species )
// To create valid json schema we need to pass information from shell wrapper here
params.subcategory_organism = "" // introduced to meet output schema
params.safeguards_status  = "" // "tak" or "nie" if "nie" it will not execute pipeline but produce valid json schema

params.input_type = "" // dummy value NOT used by this script
params.prokka_image = "" // dummy value NOT used by this script
// Core modules imports

include { augur_index_sequences } from "${modules}/viruses/augur_index_sequences.nf"
include { identify_low_quality_sequences } from "${modules}/viruses/identify_low_quality_sequences.nf"
include { augur_filter_sequences } from "${modules}/viruses/augur_filter_sequences.nf"
include { find_identical_sequences } from "${modules}/viruses/find_identical_sequences.nf"
include { augur_align } from "${modules}/viruses/augur_align.nf"
include { remove_duplicates_from_alignment } from "${modules}/viruses/remove_duplicates_from_alignment.nf"
include { iqtree } from "${modules}/viruses/iqtree.nf"
include { insert_duplicates_into_tree } from "${modules}/viruses/insert_duplicates_into_tree.nf"
include { insert_duplicates_into_alignment } from "${modules}/viruses/insert_duplicates_into_alignment.nf"
include { treetime } from "${modules}/viruses/treetime.nf"
include { augur_export } from "${modules}/viruses/augur_export.nf"
include { rescale_timetree } from "${modules}/viruses/rescale_timetree.nf"
include { prepare_microreact_json } from "${modules}/common/prepare_microreact_json.nf"

// metadata modules
include { find_country_coordinates } from "${modules}/viruses/find_country_coordinates.nf"
include { generate_colors_for_features } from "${modules}/viruses/generate_colors_for_features.nf"

// influenza specific modules
include { transform_input } from "${modules}/viruses/transform_input.nf"
include { transform_input_novel } from "${modules}/viruses/transform_input.nf"
include { adjust_metadata } from "${modules}/viruses/adjust_metadata.nf"
include { metadata_for_microreact } from "${modules}/viruses/metadata_for_microreact.nf"

// json_input
include { create_input_params_json } from "${modules}/common/create_input_params_json.nf"
include {merge_jsons} from "${modules}/viruses/merge_jsons.nf"
include {json_aggregator} from "${modules}/common/json_aggregator.nf"


workflow core {
    take:
    input_fasta
    metadata

    main:
    augur_index_sequences(input_fasta)
    identify_low_quality_sequences_out = identify_low_quality_sequences(augur_index_sequences.out)
    c1 = input_fasta.join(augur_index_sequences.out.sequence_index).join(identify_low_quality_sequences_out.out)
    augur_filter_sequences_out = augur_filter_sequences(c1, metadata)
    find_identical_sequences_out = find_identical_sequences(augur_filter_sequences_out.out)
    augur_align(find_identical_sequences_out.uniq_fasta)
    iqtree_out = iqtree(augur_align.out)
    c2 = iqtree_out.out.join(find_identical_sequences_out.duplicated_ids)
    insert_duplicates_into_tree(c2)
    c3 = augur_align.out.join(find_identical_sequences_out.duplicated_ids)
    insert_duplicates_into_alignment(c3)
    c4 = insert_duplicates_into_alignment.out.join(insert_duplicates_into_tree.out)
    treetime_out = treetime(c4, metadata)
    rescale_timetree(treetime_out.to_microreact)

    c5 = insert_duplicates_into_tree.out.join(rescale_timetree.out)

    // Here one can switch back auspice
    // augur_export(treetime_out.to_auspice)

    // Transforming metadata and prepare .microreact JSON
    find_country_coordinates(metadata)
    generate_colors_for_features(find_country_coordinates.out)
    metadata_for_microreact(generate_colors_for_features.out, metadata)
    prepare_microreact_json(metadata_for_microreact.out, c5)

    emit:
    identify_low_quality_sequences_out.json
    find_identical_sequences_out.json
    iqtree_out.json
    treetime_out.json

}

// def transformed

workflow {
    input_fasta_path = file(params.input_dir) // create path like object

    create_input_params_json_out = create_input_params_json(metadata, ExecutionDir)

    if (organism.toLowerCase() in ['influenza' , 'sars-cov-2', 'rsv' ]) {


        transformed = transform_input_novel(input_fasta_path)
                      .fastas
                      .flatten()
                      .map { file -> tuple(file.baseName, file) }

        adjusted_metadata = adjust_metadata(metadata)
        // core(transformed, adjusted_metadata)
        (identify_low_quality_channel, find_identical_sequences_channel, iqtree_channel, treetime_channel) = core(transformed, adjusted_metadata)


        // merge results for each segment
        identify_low_quality_collect = identify_low_quality_channel.map{id, file -> file }.collect()
        find_identical_sequences_collect  = find_identical_sequences_channel.map{id, file -> file }.collect()
        iqtree_collect = iqtree_channel.map{id, file -> file }.collect()
        treetime_collect = treetime_channel.map{id, file -> file }.collect()

        // add tag
        identify_low_quality_t = identify_low_quality_collect.map { files -> tuple('identify_low_quality', files)}
        find_identical_sequences_t = find_identical_sequences_collect.map { files -> tuple('find_identical_sequences', files)}
        iqtree_t = iqtree_collect.map { files -> tuple('iqtree', files)}
        treetime_t = treetime_collect.map { files ->tuple('treetime', files)}

        pair_ch = identify_low_quality_t.concat(find_identical_sequences_t, iqtree_t, treetime_t)


        meged_jsons_out  = merge_jsons(pair_ch)

        // combine results into one channele
        meged_jsons_collcet = meged_jsons_out.collect()
        to_json_aggergator = create_input_params_json_out.json.concat(meged_jsons_collcet.flatten()).collect()
        json_aggregator(to_json_aggergator, ExecutionDir)

    }
    else {
        error "Organism not supported. Please use 'sars-cov-2', 'influenza' or 'rsv'."
    }
}
