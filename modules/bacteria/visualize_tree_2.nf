process visualize_tree_2 {
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_${suffix}.json"
    tag "Visualizing the data"
    cpus 1
    memory "20 GB"                        
    time "2h"
    input:
    tuple path(tree), path(branch_lengths)
    tuple path(longlat), path(colors)
    path(metadata)
    val(suffix) // either timetree or regular tree
    output:
    path("${params.results_prefix}_${suffix}.json")
    script:
    """
    augur export v2 --tree ${tree} \
                     --metadata ${metadata} \
                     --node-data ${branch_lengths} \
                     --auspice-config /opt/docker/config/auspice_config_${params.genus}.json \
                     --colors ${colors} \
                     --lat-longs ${longlat} \
                     --output ${params.results_prefix}_${suffix}.json \
            """

}                                                                                                                                                                                                 
