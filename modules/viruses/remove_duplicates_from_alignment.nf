process remove_duplicates_from_alignment {
    container  = params.main_image
    tag "${segmentId}"
    cpus 1
    memory "30 GB"
    time "1h"
    input:
    path alignment
    path duplicated_ids

    output:
    path "deduplicated_alignment.fasta", emit: deduplicated_alignment

    script:
    """
    remove_duplicates_from_alignment.py -a ${alignment} -i ${duplicated_ids} -o deduplicated_alignment.fasta
    """
}