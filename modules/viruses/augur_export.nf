process augur_export {
    container  = params.main_image
    tag "Creating json for auspice for ${segmentId}"
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${segmentId}_auspice.json"
    cpus 1
    memory "30 GB"
    time "10m"

    input:
    tuple val(segmentId), path(tree), path(branch_lengths), path(traits), path(metadata)

    output:
    path "${segmentId}_auspice.json", emit: out

    script:
    """
    augur export v2 \
        --tree ${tree} \
        --metadata ${metadata} \
        --auspice-config /etc/auspice/auspice_config.json \
        --title ${params.results_prefix} \
        --node-data ${branch_lengths} ${traits}\
        --output ${segmentId}_auspice.json
    """
}