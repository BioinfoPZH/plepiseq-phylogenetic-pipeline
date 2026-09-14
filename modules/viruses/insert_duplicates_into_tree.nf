process insert_duplicates_into_tree {
    tag "Refining initial tree for ${segmentId}"
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_${segmentId}_filogram.nwk"
    cpus 1
    memory "10 GB"
    time "10m"
    input:
    tuple val(segmentId), path(tree), path(ids)

    output:
    tuple val(segmentId), path("${params.results_prefix}_${segmentId}_filogram.nwk")

    script:
    """
    # Re-root, collapse brancheswith poor support and reintroduce samples with identical sequences removed
    # prior to tree calculations
    MIN_SUPPORT=`echo ${params.min_support} | awk '{print \$0 * 100}'`
    python /opt/docker/custom_scripts/root_collapse_and_add_identical_seq_to_tree.py --input_mapping ${ids} \\
                                                                                     --input_tree ${tree} \\
                                                                                     --collapse_value \${MIN_SUPPORT} \\
                                                                                     --collapse \\
                                                                                     --output_prefix tree2
    cp tree2_reintroduced_identical_sequences.nwk ${params.results_prefix}_${segmentId}_filogram.nwk

    """
}
