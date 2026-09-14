process insert_duplicates_into_alignment {
    tag "${segmentId}"
    container  = params.main_image
    // publishDir "${params.results_dir}/${params.results_prefix}/", mode: 'copy', pattern: "${segmentId}_alignment_with_duplicates.fasta"

    cpus 1
    memory "30 GB"
    time "1h"
    input:
    tuple val(segmentId), path(alignment), path(ids)

    output:
    tuple val(segmentId), path("${segmentId}_alignment_with_duplicates.fasta")

    script:
    """
    add_or_remove_duplicates_from_alignment.py \
        --alignment ${alignment} \
        --duplicated_ids ${ids} \
        --action insert \
        --output ./${segmentId}_alignment_with_duplicates.fasta
    """
}