process prepare_microreact_json {
    tag "${segmentId}"
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_${segmentId}_microreactproject.microreact"

    cpus 1
    memory "20 GB"
    time "1h"

    input:
    path(microreact_metadata)
    tuple val(segmentId), path(tree_regular), path(tree_rescaled)

    output:
    path("${params.results_prefix}_${segmentId}_microreactproject.microreact")

    script:
    """
    prepare_json_for_microreact.py --input_json /opt/docker/config/microreact_config_bacteria.microreact \
                                   --classical_tree ${tree_regular} \
                                   --rescaled_tree ${tree_rescaled} \
                                   --metadata ${microreact_metadata} \
                                   --project_name ${params.results_prefix} \
                                   --output ${params.results_prefix}_${segmentId}_microreactproject.microreact
    """
}


process prepare_microreact_json_with_mst {
    container  = params.main_image
    publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${params.results_prefix}_microreactproject.microreact"

    tag "Preparing bacterial .microreact file with MST"
    cpus 1
    memory "20 GB"
    time "1h"

    input:
    path(microreact_metadata)
    tuple path(tree_regular), path(tree_rescaled)
    path(mst_tree)

    output:
    path("${params.results_prefix}_microreactproject.microreact")

    script:
    """
    python3 /opt/docker/custom_scripts/prepare_json_for_microreact.py \
        --input_json /opt/docker/config/microreact_config_bacteria.microreact \
        --classical_tree ${tree_regular} \
        --rescaled_tree ${tree_rescaled} \
        --mst_tree ${mst_tree} \
        --metadata ${microreact_metadata} \
        --project_name ${params.results_prefix} \
        --output ${params.results_prefix}_microreactproject.microreact
    """
}
