process rescale_timetree {
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_${segmentId}_chronogram.nwk"
    tag "${segmentId}"
    cpus 1
    memory "30 GB"
    time "30m"

    input:
    tuple val(segmentId), path(timetree), path(node_data)

    output:
    tuple val(segmentId), path("${params.results_prefix}_${segmentId}_chronogram.nwk")

    script:
    """

    # This allows a proper visualzation of tree in microreact (that lacks the ability to visualize time tress)
    python /opt/docker/custom_scripts/convert_nwk_to_timetree.py --tree ${segmentId}_tree3_timetree.nwk  \\
                                                                 --branches ${segmentId}_branch_lengths.json \\
                                                                 --output ${segmentId}_tree3_timetree_rescaled.nwk

    cp ${segmentId}_tree3_timetree_rescaled.nwk ${params.results_prefix}_${segmentId}_chronogram.nwk

    """
}