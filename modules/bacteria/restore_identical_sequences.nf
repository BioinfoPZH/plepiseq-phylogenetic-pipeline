process restore_identical_sequences {
    // Reroot initial tree, collapse poorly supported nodes
    // Reintroduce identical sequences that were removed prior to tree calculation
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_filogram.nwk"
    container  = params.main_image
    tag "Refining initial tree"
    cpus 1
    memory "10 GB"
    time "10m"
    input:
    path(tree)
    path(identical_sequences_mapping) 
    output:
    path("tree2_reintroduced_identical_sequences.nwk"), emit: tree
    path("${params.results_prefix}_filogram.nwk"), emit: to_publishdir
    script:
    """
    python /opt/docker/custom_scripts/root_collapse_and_add_identical_seq_to_tree.py --input_mapping ${identical_sequences_mapping} \\
                                                                                     --input_tree ${tree} \\
                                                                                     --collapse_value ${params.min_support} \\
                                                                                     --root \\
                                                                                     --collapse \\
                                                                                     --output_prefix tree2
    cp tree2_reintroduced_identical_sequences.nwk ${params.results_prefix}_filogram.nwk
    """
    
}
