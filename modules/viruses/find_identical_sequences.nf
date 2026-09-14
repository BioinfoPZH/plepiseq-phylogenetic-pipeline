process find_identical_sequences {
    container  = params.main_image
    tag "Identifying samples with identical sequences for ${segmentId}"
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "${segmentId}_valid_strains_sequence_clustering_data.json"
    cpus 1
    memory "30 GB"
    time "1h"
    input:
    tuple val(segmentId), path(fasta)

    output:
    tuple val(segmentId), path("${segmentId}_valid_strains_unique.fasta"), emit: uniq_fasta
    tuple val(segmentId), path("${segmentId}_valid_strains_ident_seq.csv"), emit: duplicated_ids
    tuple val(segmentId), path("${segmentId}_valid_strains_sequence_clustering_data.json"), emit: json

    script:
    """
    find_identical_sequences.py --input ${fasta} \
                                --output_dir . \
                                --output_prefix ${segmentId}_valid_strains \
                                --threshold 1 \
                                --segment_name ${segmentId}

    """
}