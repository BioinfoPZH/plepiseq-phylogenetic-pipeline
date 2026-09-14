// Variables for processes
def hostname = "hostname".execute().text.trim() // We need that to overwrite a default "container" options from config, used by the alphafold
ExecutionDir = new File('.').absolutePath

// ALL parameters are setup using bash wrapper except enterobase_api_token that MUST be part of nextflow config
// Comments were preserved in the  nf file for a local executor
params.input_dir = ""
params.input_type = ""
params.results_prefix = "" // Used only to 1. create subdirectory in params.results_dir and 2. as a prefix for auspice files. These prefix is used by auspice as part of an address e..g "flu_ha_h1n1_timestamp" or "sarscov2_timestamp" or "salmonella_poland_timestamp"
params.main_image = "" 
params.results_dir = ""
params.prokka_image = ""
params.threads = ""
params.metadata = "" // Path to a file with metadata
params.model = "" // Model for raxml
params.starting_trees = "" // Number of random initial trees
params.bootstrap = "" // Number of bootstraps
params.min_support = "" // Minimum support for a branch to keep it in a tree
params.genus = "" // We will supplement pipeline with clock rates for relevant genus if temporal signal in the alignment is week
params.clockrate = "" // User can still override any built-in and estimated values fron the alignment
params.skip_clockrate_estimation = "false" // Set by the shell wrapper when all samples share one sampling date
params.gen_per_year = ""

// Visualization
params.map_detail = "" // Czy próbce przypisujemy koordynaty kraju czy miasta pochodzenia. Wymagane dla microreact'a.

// User must use our config that has two profiles slurm and local, nextflow must be initialized with one of them

if ( params.genus != 'Salmonella' && params.genus != 'Escherichia' && params.genus != 'Campylobacter' ) {
    println("The program will not execute unless the provided genus is Salmonella, Escherichia, or Campylobacter.")
    System.exit(1)
} else {
    println("Running pipeline for genus: ${params.genus}")
}


if ( !workflow.profile || ( workflow.profile != "slurm" && workflow.profile != "local") ) {
   println("Nextflow run must be executed with -profile option. The specified profile must be either \"local\" or \"slurm\".")
   System.exit(1)
}

// QC params
params.threshold_Ns = ""
params.threshold_ambiguities = ""

// Path to databases (required for MST)
params.db_absolute_path_on_host= ""

// for json aggregator
params.subcategory_organism = "" // introduced to meet output schema
params.safeguards_status = "" // "tak" or "nie" if "nie" it will not execute pipeline but produce valid json schema


// modules shared with the viral pipeline
params.projectDir = ""
modules = "${params.projectDir}/modules"
include { create_input_params_json } from "${modules}/common/create_input_params_json.nf"
include {json_aggregator} from "${modules}/common/json_aggregator.nf"
include {prepare_microreact_json_with_mst} from "${modules}/common/prepare_microreact_json.nf"

// modules specific to the bacterial pipeline
include {convert_MST_to_newick} from "${modules}/bacteria/convert_mst_to_newick.nf"
include { run_prokka } from "${modules}/bacteria/run_prokka.nf"
include { run_roary } from "${modules}/bacteria/run_roary.nf"
include { augur_index_sequences } from "${modules}/bacteria/augur_index_sequences.nf"
include { augur_filter_sequences } from "${modules}/bacteria/augur_filter_sequences.nf"
include { prepare_SNPs_alignment } from "${modules}/bacteria/prepare_SNPs_alignment.nf"
include { identify_identical_sequences } from "${modules}/bacteria/identify_identical_sequences.nf"
include { run_raxml } from "${modules}/bacteria/run_raxml.nf"
include { restore_identical_sequences } from "${modules}/bacteria/restore_identical_sequences.nf"
include { add_temporal_data } from "${modules}/bacteria/add_temporal_data.nf"
include { run_dummy_refine } from "${modules}/bacteria/run_dummy_refine.nf"
include { find_country_coordinates } from "${modules}/bacteria/find_country_coordinates.nf"
include { generate_colors_for_features } from "${modules}/bacteria/generate_colors_for_features.nf"
include { visualize_tree_1 } from "${modules}/bacteria/visualize_tree_1.nf"
include { visualize_tree_2 } from "${modules}/bacteria/visualize_tree_2.nf"
include { metadata_for_microreact } from "${modules}/bacteria/metadata_for_microreact.nf"
include { prepare_MST } from "${modules}/bacteria/prepare_MST.nf"
include { save_input_to_log } from "${modules}/bacteria/save_input_to_log.nf"

// MAIN WORKFLOW //

workflow {

Channel
    .fromPath("${params.metadata}")
    .set {metadata_channel}


create_input_params_json_out = create_input_params_json(metadata_channel, ExecutionDir)
// Prepare gff input

if (params.input_type == 'fasta') {
    Channel
        .fromPath("${params.input_dir}/*")
        .map { file -> tuple(file.getName().split("\\.")[0], file) }
        .set { initial_fasta }

    gff_input = run_prokka(initial_fasta).collect()

} else if (params.input_type == 'gff') {
    Channel
        .fromPath("${params.input_dir}/*")
        .collect()
        .set { gff_input }

} else {
    println("--input_type must be either fasta or gff")
    System.exit(1)
}

roary_out = run_roary(gff_input)

find_country_coordinates_out = find_country_coordinates(metadata_channel)
generate_colors_for_features_out = generate_colors_for_features(find_country_coordinates_out)

augur_index_sequences_out = augur_index_sequences(roary_out)

augur_filter_sequences_out = augur_filter_sequences(augur_index_sequences_out, metadata_channel)

prepare_SNPs_alignment_and_partition_out = prepare_SNPs_alignment(augur_filter_sequences_out.to_SNPs_alignment)

identify_identical_sequences_out = identify_identical_sequences(prepare_SNPs_alignment_and_partition_out)

run_raxml_out = run_raxml(identify_identical_sequences_out.to_raxml)

restore_identical_sequences_out = restore_identical_sequences(run_raxml_out.tree, identify_identical_sequences_out.identical_sequences_mapping)

add_temporal_data_out = add_temporal_data(restore_identical_sequences_out.tree, augur_filter_sequences_out.alignment_and_metadata)

add_dummy_data_out = run_dummy_refine(restore_identical_sequences_out.tree, augur_filter_sequences_out.alignment_and_metadata) 


metadata_for_microreact_out = metadata_for_microreact(generate_colors_for_features_out, metadata_channel)

// Here we can switch back visualization with auspice

// visualize_tree_out_1 = visualize_tree_1(add_temporal_data_out.to_auspice, generate_colors_for_features_out, metadata_channel, "timetree")
// visualize_tree_out_2 = visualize_tree_2(add_dummy_data_out, generate_colors_for_features_out, metadata_channel, "regulartree")
// save_input_to_log(gff_input)

// create MST

prepare_MST_out = prepare_MST(metadata_channel)
convert_MST_to_newick_out = convert_MST_to_newick(prepare_MST_out.edges, metadata_channel)

prepare_microreact_json_out = prepare_microreact_json_with_mst(metadata_for_microreact_out, add_temporal_data_out.to_microreact, convert_MST_to_newick_out)

// json aggegator


pair_ch = create_input_params_json_out.json.concat(augur_filter_sequences_out.json, identify_identical_sequences_out.json, run_raxml_out.json, add_temporal_data_out.json)
pair_ch = pair_ch.collect()

json_aggregator_out = json_aggregator(pair_ch, ExecutionDir)


}
