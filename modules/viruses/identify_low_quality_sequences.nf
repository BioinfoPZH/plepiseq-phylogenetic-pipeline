process identify_low_quality_sequences {
    tag "identify low quality sequence for ${segmentId}"
    // publishDir "${params.results_dir}/${params.results_prefix}/subschemas", mode: 'copy', pattern: "${segmentId}_sequence_filtering_data.json"
    container  = params.main_image
    cpus 1
    memory "30 GB"
    time "1h"
    input:
    tuple val(segmentId), path(index_csv)

    output:
    tuple val(segmentId), path("invalid_strains.txt"), emit: out
    tuple val(segmentId), path("${segmentId}_sequence_filtering_data.json"), emit: json

    script:
    """
    identify_low_quality_sequences.py \
        --output_dir . \
        --threshold_Ns ${params.threshold_Ns} \
        --threshold_ambiguities ${params.threshold_ambiguities} \
        --json_out ${segmentId}_sequence_filtering_data.json \
        --segment_name ${segmentId} \
        --input ${index_csv}
    """
}