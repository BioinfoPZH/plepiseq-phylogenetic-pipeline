process convert_MST_to_newick {
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_MST.nwk"

    tag "Converting minimum spanning tree to sample-level Newick"
    cpus 1
    memory "2 GB"
    time "10m"

    input:
    path(mst_edges)
    path(metadata)

    output:
    path("${params.results_prefix}_MST.nwk")

    script:
    """
    python3 /opt/docker/custom_scripts/convert_mst_to_newick.py \
        --mst-edges ${mst_edges} \
        --metadata ${metadata} \
        --output ${params.results_prefix}_MST.nwk
    """
}
